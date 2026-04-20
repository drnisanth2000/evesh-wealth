// supabase/functions/check-watchlist-rules/index.ts
// Runs daily at 22:30 IST (17:00 UTC) via pg_cron.
// Evaluates all active watchlist rules against current NAV/holdings data.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

interface WatchlistRule {
  id: string
  owner_id: string
  member_id: string | null
  amfi_code: number | null
  fund_name: string | null
  rule_type: string
  threshold_type: string
  threshold_value: number
  direction: string
  asset_class_key: string | null
  is_active: boolean
  last_triggered_at: string | null
  cooldown_hours: number
}

interface AlertCandidate {
  owner_id: string
  alert_type: string
  severity: string
  title: string
  body: string
  amfi_code: number | null
  member_id: string | null
  dedup_key: string
}

interface Holding {
  amfi_code: number
  units: number
  invested: number
  current_value: number
  gain_pct: number
  asset_class: string
}

Deno.serve(async () => {
  const supabase = createClient(supabaseUrl, supabaseServiceKey)
  const today = new Date().toISOString().slice(0, 10) // YYYY-MM-DD

  // 1. Fetch all active rules
  const { data: rules, error: rulesErr } = await supabase
    .from('watchlist_rules')
    .select('*')
    .eq('is_active', true)

  if (rulesErr || !rules?.length) {
    return new Response(JSON.stringify({ message: 'No active rules', error: rulesErr }))
  }

  // 2. Fetch all NAVs for referenced funds
  const amfiCodes = [...new Set(rules.filter((r: WatchlistRule) => r.amfi_code).map((r: WatchlistRule) => r.amfi_code!))]
  let navMap: Record<number, number> = {}
  if (amfiCodes.length > 0) {
    const { data: navData } = await supabase
      .from('fund_master')
      .select('amfi_code, latest_nav')
      .in_('amfi_code', amfiCodes)
    navMap = Object.fromEntries((navData ?? []).map((r: any) => [r.amfi_code, r.latest_nav ?? 0]))
  }

  // 3. Group rules by owner
  const rulesByOwner: Record<string, WatchlistRule[]> = {}
  for (const rule of rules as WatchlistRule[]) {
    ;(rulesByOwner[rule.owner_id] ??= []).push(rule)
  }

  // 4. Fetch transactions for all owners with amount/pct rules
  const ownerIds = Object.keys(rulesByOwner)
  const needsHoldings = rules.some((r: WatchlistRule) => r.threshold_type !== 'nav' || r.rule_type === 'allocation_drift')
  let holdingsByOwner: Record<string, Holding[]> = {}

  if (needsHoldings) {
    const { data: txs } = await supabase
      .from('transactions')
      .select('owner_id, member_id, amfi_code, amount, units, tx_type, fund_master(tax_category, category)')
      .in_('owner_id', ownerIds)

    // Compute holdings per owner per fund
    for (const tx of (txs ?? []) as any[]) {
      const key = tx.owner_id
      if (!holdingsByOwner[key]) holdingsByOwner[key] = []

      const isPurchase = ['BUY', 'SIP', 'SWITCH-IN', 'STP-IN', 'BONUS', 'TRANSFER-IN'].includes(tx.tx_type?.toUpperCase())
      const txUnits = tx.units ?? (tx.amount / 1) // fallback
      const existing = holdingsByOwner[key].find((h: Holding) => h.amfi_code === tx.amfi_code)

      if (existing) {
        if (isPurchase) {
          existing.units += txUnits
          existing.invested += tx.amount
        } else {
          const ratio = existing.units > 0 ? Math.min(txUnits / existing.units, 1) : 0
          existing.invested -= existing.invested * ratio
          existing.units -= txUnits
        }
      } else {
        holdingsByOwner[key].push({
          amfi_code: tx.amfi_code,
          units: isPurchase ? txUnits : -txUnits,
          invested: isPurchase ? tx.amount : -tx.amount,
          current_value: 0,
          gain_pct: 0,
          asset_class: mapTaxCategoryToAssetClass(tx.fund_master?.tax_category, tx.fund_master?.category),
        })
      }
    }

    // Compute current values
    for (const holdings of Object.values(holdingsByOwner)) {
      for (const h of holdings) {
        if (h.units <= 0.01) continue
        const nav = navMap[h.amfi_code] ?? 0
        h.current_value = h.units * nav
        h.gain_pct = h.invested > 0 ? ((h.current_value - h.invested) / h.invested) * 100 : 0
      }
    }
  }

  // 5. Evaluate each rule
  const alerts: AlertCandidate[] = []
  const triggeredRuleIds: string[] = []
  const now = new Date()

  for (const [ownerId, ownerRules] of Object.entries(rulesByOwner)) {
    const holdings = holdingsByOwner[ownerId] ?? []

    for (const rule of ownerRules) {
      // Cooldown check
      if (rule.last_triggered_at) {
        const lastTriggered = new Date(rule.last_triggered_at)
        const cooldownMs = rule.cooldown_hours * 60 * 60 * 1000
        if (now.getTime() - lastTriggered.getTime() < cooldownMs) continue
      }

      const breached = evaluateRule(rule, navMap, holdings)
      if (!breached) continue

      const { severity, title, body } = buildAlert(rule, navMap, holdings)
      alerts.push({
        owner_id: ownerId,
        alert_type: ruleTypeToAlertType(rule.rule_type),
        severity,
        title,
        body,
        amfi_code: rule.amfi_code,
        member_id: rule.member_id,
        dedup_key: `${rule.rule_type}|${rule.id}|${today}`,
      })
      triggeredRuleIds.push(rule.id)
    }
  }

  // 6. Insert alerts (ignore dedup conflicts)
  if (alerts.length > 0) {
    const { error: insertErr } = await supabase
      .from('alert_log')
      .upsert(alerts.map(a => ({
        ...a,
        is_read: false,
        created_at: new Date().toISOString(),
      })), { onConflict: 'dedup_key', ignoreDuplicates: true })

    if (insertErr) console.error('Insert error:', insertErr)
  }

  // 7. Update last_triggered_at
  if (triggeredRuleIds.length > 0) {
    await supabase
      .from('watchlist_rules')
      .update({ last_triggered_at: new Date().toISOString() })
      .in_('id', triggeredRuleIds)
  }

  console.log(`Checked ${rules.length} rules, generated ${alerts.length} alerts`)
  return new Response(JSON.stringify({
    rules_checked: rules.length,
    alerts_generated: alerts.length,
  }))
})

// ─── Helper Functions ────────────────────────────────────────────────────────

function evaluateRule(
  rule: WatchlistRule,
  navMap: Record<number, number>,
  holdings: Holding[],
): boolean {
  const nav = rule.amfi_code ? (navMap[rule.amfi_code] ?? 0) : 0
  const holding = holdings.find(h => h.amfi_code === rule.amfi_code)

  switch (rule.rule_type) {
    case 'stop_loss': {
      if (rule.threshold_type === 'nav') return nav > 0 && nav <= rule.threshold_value
      if (rule.threshold_type === 'amount') return (holding?.current_value ?? 0) > 0 && (holding?.current_value ?? 0) <= rule.threshold_value
      if (rule.threshold_type === 'pct') return (holding?.gain_pct ?? 0) <= -rule.threshold_value
      return false
    }
    case 'gain_harvest': {
      if (rule.threshold_type === 'nav') return nav >= rule.threshold_value
      if (rule.threshold_type === 'amount') return (holding?.current_value ?? 0) >= rule.threshold_value
      if (rule.threshold_type === 'pct') return (holding?.gain_pct ?? 0) >= rule.threshold_value
      return false
    }
    case 'price_target':
      return nav >= rule.threshold_value
    case 'allocation_drift': {
      if (!rule.asset_class_key) return false
      const totalValue = holdings.reduce((s, h) => s + Math.max(h.current_value, 0), 0)
      if (totalValue <= 0) return false
      const classValue = holdings
        .filter(h => h.asset_class === rule.asset_class_key)
        .reduce((s, h) => s + Math.max(h.current_value, 0), 0)
      const currentPct = (classValue / totalValue) * 100
      // For drift rules, threshold_value is the max drift % allowed
      const drift = Math.abs(currentPct - rule.threshold_value)
      return drift > rule.threshold_value
    }
    default:
      return false
  }
}

function buildAlert(
  rule: WatchlistRule,
  navMap: Record<number, number>,
  holdings: Holding[],
): { severity: string; title: string; body: string } {
  const nav = rule.amfi_code ? (navMap[rule.amfi_code] ?? 0) : 0
  const holding = holdings.find(h => h.amfi_code === rule.amfi_code)
  const name = rule.fund_name ?? 'Fund'

  switch (rule.rule_type) {
    case 'stop_loss': {
      const current = rule.threshold_type === 'nav'
        ? `₹${nav.toFixed(2)}`
        : rule.threshold_type === 'amount'
          ? `₹${Math.round(holding?.current_value ?? 0).toLocaleString('en-IN')}`
          : `${(holding?.gain_pct ?? 0).toFixed(1)}%`
      return {
        severity: 'URGENT',
        title: `Stop-Loss: ${name}`,
        body: `${name} has dropped below your stop-loss of ${formatThreshold(rule)}. Current: ${current}.`,
      }
    }
    case 'gain_harvest': {
      const current = rule.threshold_type === 'pct'
        ? `${(holding?.gain_pct ?? 0).toFixed(1)}%`
        : `₹${nav.toFixed(2)}`
      return {
        severity: 'MEDIUM',
        title: `Gain Harvest: ${name}`,
        body: `${name} has crossed your gain target of ${formatThreshold(rule)}. Current: ${current}.`,
      }
    }
    case 'price_target':
      return {
        severity: 'MEDIUM',
        title: `Price Target: ${name}`,
        body: `${name} NAV has reached ₹${nav.toFixed(2)}. Your target was ₹${rule.threshold_value.toFixed(2)}.`,
      }
    case 'allocation_drift':
      return {
        severity: 'URGENT',
        title: `Allocation Drift: ${rule.asset_class_key}`,
        body: `Your ${rule.asset_class_key} allocation has drifted beyond your ${rule.threshold_value}% threshold. Consider rebalancing.`,
      }
    default:
      return { severity: 'MEDIUM', title: 'Watchlist Alert', body: 'A watchlist rule was triggered.' }
  }
}

function formatThreshold(rule: WatchlistRule): string {
  if (rule.threshold_type === 'nav') return `₹${rule.threshold_value.toFixed(2)}`
  if (rule.threshold_type === 'amount') return `₹${Math.round(rule.threshold_value).toLocaleString('en-IN')}`
  return `${rule.threshold_value.toFixed(1)}%`
}

function ruleTypeToAlertType(ruleType: string): string {
  switch (ruleType) {
    case 'stop_loss': return 'STOPLOSS'
    case 'gain_harvest': return 'PRICE_HARVEST'
    case 'price_target': return 'PRICE_HARVEST'
    case 'allocation_drift': return 'REBALANCE_DRIFT'
    default: return 'SYSTEM'
  }
}

function mapTaxCategoryToAssetClass(taxCategory?: string, category?: string): string {
  const cat = (category ?? '').toLowerCase()
  if (cat.includes('liquid') || cat.includes('money market') || cat.includes('overnight')) return 'liquid'
  switch ((taxCategory ?? '').toLowerCase()) {
    case 'equity': return 'coreEquity'
    case 'hybrid-e': case 'hybrid-d': return 'hybrid'
    case 'debt': return 'debt'
    case 'gold': case 'gold etf': return 'gold'
    case 'international': return 'alternate'
    default: return 'alternate'
  }
}
