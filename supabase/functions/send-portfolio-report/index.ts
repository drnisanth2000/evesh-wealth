// supabase/functions/send-portfolio-report/index.ts
// Generates HTML email portfolio reports: weekly, monthly, yearly, onetime.
// Called by pg_cron or on-demand from the client.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')!

type ReportType = 'weekly' | 'monthly' | 'yearly' | 'onetime'

interface PortfolioHolding {
  amfi_code: number
  fund_name: string
  units: number
  invested: number
  current_value: number
  gain_pct: number
  weight_pct: number
  asset_class: string
}

Deno.serve(async (req) => {
  const supabase = createClient(supabaseUrl, supabaseServiceKey)

  // Determine report type
  let reportType: ReportType = 'weekly'
  let specificOwnerId: string | null = null

  try {
    const body = await req.json()
    reportType = body.report_type ?? 'weekly'
    specificOwnerId = body.owner_id ?? null
  } catch {
    // Called by cron with no body — determine from day
    const now = new Date()
    const day = now.getUTCDay() // 0=Sun
    const date = now.getUTCDate()
    const month = now.getUTCMonth() // 0=Jan

    if (month === 0 && date === 1) reportType = 'yearly'
    else if (date === 1) reportType = 'monthly'
    else if (day === 0) reportType = 'weekly'
  }

  const prefKey = reportType === 'onetime' ? null : `report_${reportType}`

  // Fetch eligible users
  let usersQuery = supabase
    .from('profiles')
    .select('id, email, full_name, notification_prefs')

  if (specificOwnerId) {
    usersQuery = usersQuery.eq('id', specificOwnerId)
  }

  const { data: users, error: usersErr } = await usersQuery
  if (usersErr || !users?.length) {
    return new Response(JSON.stringify({ message: 'No users', error: usersErr }))
  }

  // Filter by pref
  const eligibleUsers = specificOwnerId
    ? users
    : users.filter((u: any) => {
        const prefs = u.notification_prefs ?? {}
        return prefs.email !== false && (prefKey ? prefs[prefKey] !== false : true)
      })

  let sentCount = 0

  for (const user of eligibleUsers) {
    try {
      // Fetch transactions for this user
      const { data: txs } = await supabase
        .from('transactions')
        .select('amfi_code, amount, units, tx_type, fund_master(fund_name, latest_nav, tax_category, category)')
        .eq('owner_id', user.id)

      if (!txs?.length) continue

      // Compute holdings
      const holdingsMap: Record<number, PortfolioHolding> = {}
      for (const tx of txs as any[]) {
        const code = tx.amfi_code
        const isPurchase = ['BUY', 'SIP', 'SWITCH-IN', 'STP-IN', 'BONUS', 'TRANSFER-IN'].includes(tx.tx_type?.toUpperCase())

        if (!holdingsMap[code]) {
          holdingsMap[code] = {
            amfi_code: code,
            fund_name: tx.fund_master?.fund_name ?? `Fund ${code}`,
            units: 0,
            invested: 0,
            current_value: 0,
            gain_pct: 0,
            weight_pct: 0,
            asset_class: mapAssetClass(tx.fund_master?.tax_category, tx.fund_master?.category),
          }
        }

        const h = holdingsMap[code]
        if (isPurchase) {
          h.units += tx.units ?? 0
          h.invested += tx.amount ?? 0
        } else {
          const ratio = h.units > 0 ? Math.min((tx.units ?? 0) / h.units, 1) : 0
          h.invested -= h.invested * ratio
          h.units -= tx.units ?? 0
        }
      }

      // Compute current values
      const holdings = Object.values(holdingsMap).filter(h => h.units > 0.01)
      let totalValue = 0
      let totalInvested = 0
      for (const h of holdings) {
        const nav = (txs as any[]).find(t => t.amfi_code === h.amfi_code)?.fund_master?.latest_nav ?? 0
        h.current_value = h.units * nav
        totalValue += h.current_value
        totalInvested += h.invested
        h.gain_pct = h.invested > 0 ? ((h.current_value - h.invested) / h.invested) * 100 : 0
      }

      // Compute weights
      for (const h of holdings) {
        h.weight_pct = totalValue > 0 ? (h.current_value / totalValue) * 100 : 0
      }

      // Sort by value descending
      holdings.sort((a, b) => b.current_value - a.current_value)

      const totalGainPct = totalInvested > 0 ? ((totalValue - totalInvested) / totalInvested) * 100 : 0
      const totalGain = totalValue - totalInvested

      // Build allocation breakdown
      const allocationMap: Record<string, number> = {}
      for (const h of holdings) {
        allocationMap[h.asset_class] = (allocationMap[h.asset_class] ?? 0) + h.current_value
      }
      const allocation = Object.entries(allocationMap).map(([cls, val]) => ({
        asset_class: cls,
        value: val,
        pct: totalValue > 0 ? (val / totalValue) * 100 : 0,
      })).sort((a, b) => b.pct - a.pct)

      // Top movers (for weekly/monthly)
      const topGainers = [...holdings].sort((a, b) => b.gain_pct - a.gain_pct).slice(0, 3)
      const topLosers = [...holdings].sort((a, b) => a.gain_pct - b.gain_pct).slice(0, 3)

      // Build report title
      const dateStr = new Date().toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })
      const reportTitles: Record<ReportType, string> = {
        weekly: `Weekly Portfolio Report — ${dateStr}`,
        monthly: `Monthly Portfolio Report — ${dateStr}`,
        yearly: `Yearly Portfolio Report — ${dateStr}`,
        onetime: `Portfolio Snapshot — ${dateStr}`,
      }

      // Generate HTML
      const html = buildReportHtml({
        reportType,
        title: reportTitles[reportType],
        userName: user.full_name ?? 'Investor',
        totalValue,
        totalInvested,
        totalGain,
        totalGainPct,
        holdings,
        allocation,
        topGainers,
        topLosers,
      })

      // Send via Resend
      await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${RESEND_API_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          from: 'eVesh <reports@evesh.in>',
          to: [user.email],
          subject: reportTitles[reportType],
          html,
        }),
      })

      sentCount++
    } catch (e) {
      console.error(`Report failed for ${user.id}:`, e)
    }
  }

  return new Response(JSON.stringify({
    report_type: reportType,
    users_eligible: eligibleUsers.length,
    reports_sent: sentCount,
  }))
})

// ─── HTML Builder ────────────────────────────────────────────────────────────

function buildReportHtml(data: {
  reportType: ReportType
  title: string
  userName: string
  totalValue: number
  totalInvested: number
  totalGain: number
  totalGainPct: number
  holdings: PortfolioHolding[]
  allocation: { asset_class: string; value: number; pct: number }[]
  topGainers: PortfolioHolding[]
  topLosers: PortfolioHolding[]
}): string {
  const fmt = (n: number) => `₹${Math.round(n).toLocaleString('en-IN')}`
  const pct = (n: number) => `${n >= 0 ? '+' : ''}${n.toFixed(1)}%`
  const gainColor = data.totalGain >= 0 ? '#1B8A5A' : '#E53935'

  let holdingsRows = data.holdings.slice(0, 20).map(h => `
    <tr>
      <td style="padding:8px 12px;border-bottom:1px solid #2a2a2a;color:#e0e0e0;font-size:13px;">${h.fund_name}</td>
      <td style="padding:8px 12px;border-bottom:1px solid #2a2a2a;color:#e0e0e0;font-size:13px;text-align:right;">${fmt(h.current_value)}</td>
      <td style="padding:8px 12px;border-bottom:1px solid #2a2a2a;font-size:13px;text-align:right;color:${h.gain_pct >= 0 ? '#1B8A5A' : '#E53935'};">${pct(h.gain_pct)}</td>
      <td style="padding:8px 12px;border-bottom:1px solid #2a2a2a;color:#e0e0e0;font-size:13px;text-align:right;">${h.weight_pct.toFixed(1)}%</td>
    </tr>
  `).join('')

  let allocationRows = data.allocation.map(a => `
    <tr>
      <td style="padding:6px 12px;color:#e0e0e0;font-size:13px;">${a.asset_class}</td>
      <td style="padding:6px 12px;color:#e0e0e0;font-size:13px;text-align:right;">${fmt(a.value)}</td>
      <td style="padding:6px 12px;color:#e0e0e0;font-size:13px;text-align:right;">${a.pct.toFixed(1)}%</td>
    </tr>
  `).join('')

  let moversSection = ''
  if (data.reportType !== 'onetime') {
    const gainerRows = data.topGainers.map(h => `<li style="color:#1B8A5A;font-size:13px;margin-bottom:4px;">${h.fund_name}: ${pct(h.gain_pct)}</li>`).join('')
    const loserRows = data.topLosers.map(h => `<li style="color:#E53935;font-size:13px;margin-bottom:4px;">${h.fund_name}: ${pct(h.gain_pct)}</li>`).join('')
    moversSection = `
      <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:24px;">
        <tr>
          <td width="50%" valign="top" style="padding-right:12px;">
            <h3 style="color:#1B8A5A;font-size:14px;margin:0 0 8px;">Top Gainers</h3>
            <ul style="margin:0;padding-left:16px;">${gainerRows}</ul>
          </td>
          <td width="50%" valign="top" style="padding-left:12px;">
            <h3 style="color:#E53935;font-size:14px;margin:0 0 8px;">Top Losers</h3>
            <ul style="margin:0;padding-left:16px;">${loserRows}</ul>
          </td>
        </tr>
      </table>
    `
  }

  return `
    <!DOCTYPE html>
    <html>
    <head><meta charset="utf-8"></head>
    <body style="margin:0;padding:0;background:#121212;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;">
      <table width="100%" cellpadding="0" cellspacing="0" style="background:#121212;">
        <tr><td align="center" style="padding:24px 16px;">
          <table width="600" cellpadding="0" cellspacing="0" style="background:#1e1e1e;border-radius:12px;overflow:hidden;">
            <!-- Header -->
            <tr><td style="background:#1B8A5A;padding:24px 32px;">
              <h1 style="color:white;margin:0;font-size:20px;">eVesh</h1>
              <p style="color:rgba(255,255,255,0.85);margin:8px 0 0;font-size:14px;">${data.title}</p>
            </td></tr>

            <!-- Summary -->
            <tr><td style="padding:24px 32px;">
              <p style="color:#999;margin:0 0 16px;font-size:14px;">Hello ${data.userName},</p>
              <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:24px;">
                <tr>
                  <td style="background:#252525;border-radius:8px;padding:16px;text-align:center;width:33%;">
                    <div style="color:#999;font-size:11px;margin-bottom:4px;">Portfolio Value</div>
                    <div style="color:#e0e0e0;font-size:18px;font-weight:600;">${fmt(data.totalValue)}</div>
                  </td>
                  <td width="12"></td>
                  <td style="background:#252525;border-radius:8px;padding:16px;text-align:center;width:33%;">
                    <div style="color:#999;font-size:11px;margin-bottom:4px;">Total Gain/Loss</div>
                    <div style="color:${gainColor};font-size:18px;font-weight:600;">${fmt(data.totalGain)}</div>
                  </td>
                  <td width="12"></td>
                  <td style="background:#252525;border-radius:8px;padding:16px;text-align:center;width:33%;">
                    <div style="color:#999;font-size:11px;margin-bottom:4px;">Return</div>
                    <div style="color:${gainColor};font-size:18px;font-weight:600;">${pct(data.totalGainPct)}</div>
                  </td>
                </tr>
              </table>

              ${moversSection}

              <!-- Holdings Table -->
              <h3 style="color:#e0e0e0;font-size:14px;margin:0 0 12px;">Holdings</h3>
              <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:24px;">
                <tr style="background:#252525;">
                  <th style="padding:8px 12px;text-align:left;color:#999;font-size:11px;font-weight:600;">Fund</th>
                  <th style="padding:8px 12px;text-align:right;color:#999;font-size:11px;font-weight:600;">Value</th>
                  <th style="padding:8px 12px;text-align:right;color:#999;font-size:11px;font-weight:600;">Gain</th>
                  <th style="padding:8px 12px;text-align:right;color:#999;font-size:11px;font-weight:600;">Weight</th>
                </tr>
                ${holdingsRows}
              </table>

              <!-- Allocation -->
              <h3 style="color:#e0e0e0;font-size:14px;margin:0 0 12px;">Asset Allocation</h3>
              <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:24px;">
                <tr style="background:#252525;">
                  <th style="padding:6px 12px;text-align:left;color:#999;font-size:11px;">Asset Class</th>
                  <th style="padding:6px 12px;text-align:right;color:#999;font-size:11px;">Value</th>
                  <th style="padding:6px 12px;text-align:right;color:#999;font-size:11px;">Weight</th>
                </tr>
                ${allocationRows}
              </table>
            </td></tr>

            <!-- Footer -->
            <tr><td style="padding:16px 32px;border-top:1px solid #2a2a2a;">
              <p style="color:#666;font-size:12px;margin:0;text-align:center;">
                View full details at <a href="https://evesh.netlify.app" style="color:#1B8A5A;">evesh.netlify.app</a>
              </p>
            </td></tr>
          </table>
        </td></tr>
      </table>
    </body>
    </html>
  `
}

function mapAssetClass(taxCategory?: string, category?: string): string {
  const cat = (category ?? '').toLowerCase()
  if (cat.includes('liquid') || cat.includes('money market') || cat.includes('overnight')) return 'Liquid'
  switch ((taxCategory ?? '').toLowerCase()) {
    case 'equity': return 'Equity'
    case 'hybrid-e': case 'hybrid-d': return 'Hybrid'
    case 'debt': return 'Debt'
    case 'gold': case 'gold etf': return 'Gold'
    case 'international': return 'International'
    default: return 'Other'
  }
}
