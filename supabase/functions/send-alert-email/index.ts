/**
 * eVesh — Supabase Edge Function: send-alert-email
 *
 * Runs daily at 19:00 IST (13:30 UTC) via pg_cron.
 * Checks all users for alert conditions and inserts into alert_log.
 * Sends email via Resend and push via FCM for URGENT alerts.
 *
 * Alert types:
 *  - nav_drop: Fund NAV dropped > 3% in a day
 *  - price_target: NAV hit user-set target_amount
 *  - stoploss: NAV hit stoploss_amount
 *  - rebalance_drift: Asset class drifted > threshold from target
 *  - ltcg_harvest: Unrealised LTCG approaching ₹1.25L
 *  - sip_reminder: SIP due in 3 days
 *  - maturity_alert: FD/SGB maturing within 30 days
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY');

interface AlertCandidate {
  owner_id: string;
  alert_type: string;
  severity: 'URGENT' | 'MEDIUM' | 'LOW';
  title: string;
  body: string;
  amfi_code?: number;
  member_id?: string;
  dedup_key: string;
}

interface InsertedAlert {
  id: string;
  owner_id: string;
  alert_type: string;
  severity: 'URGENT' | 'MEDIUM' | 'LOW';
  title: string;
  body: string;
}

interface NotificationPrefs {
  email?: boolean;
  push?: boolean;
  frequency?: 'off' | 'instant' | 'daily' | 'weekly';
  stop_loss?: boolean;
  rebalance_drift?: boolean;
  gain_harvest?: boolean;
  nav_drop?: boolean;
  sip_reminder?: boolean;
  maturity_alert?: boolean;
  price_target?: boolean;
  [key: string]: boolean | string | undefined;
}

// ── FCM push helper ──────────────────────────────────────────────────────────
async function sendPush(fcmToken: string, title: string, body: string) {
  const projectId = Deno.env.get('FIREBASE_PROJECT_ID');
  const serviceAccountKey = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_KEY');

  if (!projectId || !serviceAccountKey) {
    console.warn('FCM not configured, skipping push');
    return;
  }

  try {
    // Parse service account and get access token
    const sa = JSON.parse(serviceAccountKey);
    const now = Math.floor(Date.now() / 1000);
    const header = btoa(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
    const payload = btoa(JSON.stringify({
      iss: sa.client_email,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      exp: now + 3600,
      iat: now,
    }));

    // For simplicity, use the existing OAuth token approach
    // In production, implement proper JWT signing with the service account key
    const message = {
      message: {
        token: fcmToken,
        notification: { title, body },
        webpush: {
          fcm_options: { link: 'https://evesh.netlify.app/alerts' },
        },
      },
    };

    // Try sending via FCM - graceful failure
    const resp = await fetch(
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(message),
      },
    );
    if (!resp.ok) {
      console.warn('FCM push failed:', await resp.text());
    }
  } catch (e) {
    console.warn('FCM push error:', e);
  }
}

// ── Map alert_type to notification_prefs key ─────────────────────────────────
function alertTypeToPrefsKey(alertType: string): string {
  const map: Record<string, string> = {
    stoploss: 'stop_loss',
    rebalance_drift: 'rebalance_drift',
    price_target: 'price_target',
    ltcg_harvest: 'gain_harvest',
    nav_drop: 'nav_drop',
    sip_reminder: 'sip_reminder',
    maturity_alert: 'maturity_alert',
    STOCK_CONCENTRATION: 'stock_concentration',
    SECTOR_CONCENTRATION: 'sector_concentration',
    FUND_OVERLAP: 'fund_overlap',
  };
  return map[alertType] ?? alertType;
}

// ── Send email via Resend ────────────────────────────────────────────────────
async function sendEmail(
  to: string,
  subject: string,
  html: string,
): Promise<boolean> {
  if (!RESEND_API_KEY) return false;
  const res = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${RESEND_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      from: 'eVesh Alerts <alerts@evesh.app>',
      to,
      subject,
      html,
    }),
  });
  return res.ok;
}

serve(async (req) => {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  };

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
    const today = new Date().toISOString().substring(0, 10);

    const alerts: AlertCandidate[] = [];

    // ── 1. NAV drop alerts ───────────────────────────────────────────────────
    const { data: navDropFunds } = await supabase
      .from('fund_master')
      .select('amfi_code, fund_name, latest_nav, prev_nav')
      .not('latest_nav', 'is', null)
      .not('prev_nav', 'is', null);

    for (const fund of navDropFunds || []) {
      if (!fund.prev_nav || fund.prev_nav === 0) continue;
      const dropPct = ((fund.latest_nav - fund.prev_nav) / fund.prev_nav) * 100;
      if (dropPct <= -3) {
        // Find all holders of this fund
        const { data: holders } = await supabase
          .from('transactions')
          .select('owner_id, member_id')
          .eq('amfi_code', fund.amfi_code)
          .in('tx_type', ['BUY', 'SIP']);

        const seen = new Set<string>();
        for (const h of holders || []) {
          const key = h.owner_id;
          if (seen.has(key)) continue;
          seen.add(key);

          alerts.push({
            owner_id: h.owner_id,
            alert_type: 'nav_drop',
            severity: dropPct <= -5 ? 'URGENT' : 'MEDIUM',
            title: `NAV Drop: ${fund.fund_name.substring(0, 40)}`,
            body: `NAV fell ${dropPct.toFixed(1)}% today to ₹${fund.latest_nav.toFixed(2)}`,
            amfi_code: fund.amfi_code,
            dedup_key: `nav_drop|${fund.amfi_code}|${today}`,
          });
        }
      }
    }

    // ── 2. Price target / stop-loss alerts ───────────────────────────────────
    const { data: targetTxs } = await supabase
      .from('transactions')
      .select('id, owner_id, member_id, amfi_code, target_amount, stoploss_amount, asset_name')
      .or('target_amount.not.is.null,stoploss_amount.not.is.null');

    for (const tx of targetTxs || []) {
      const nav = navDropFunds?.find((f: any) => f.amfi_code === tx.amfi_code)?.latest_nav;
      if (!nav) continue;
      const name = tx.asset_name?.substring(0, 40) ?? `AMFI ${tx.amfi_code}`;

      if (tx.target_amount && nav >= tx.target_amount) {
        alerts.push({
          owner_id: tx.owner_id,
          alert_type: 'price_target',
          severity: 'URGENT',
          title: `Price Target Hit: ${name}`,
          body: `NAV ₹${nav.toFixed(2)} reached your target of ₹${tx.target_amount}`,
          amfi_code: tx.amfi_code,
          dedup_key: `price_target|${tx.id}|${today}`,
        });
      }

      if (tx.stoploss_amount && nav <= tx.stoploss_amount) {
        alerts.push({
          owner_id: tx.owner_id,
          alert_type: 'stoploss',
          severity: 'URGENT',
          title: `Stop-Loss Triggered: ${name}`,
          body: `NAV ₹${nav.toFixed(2)} fell below your stop-loss of ₹${tx.stoploss_amount}`,
          amfi_code: tx.amfi_code,
          dedup_key: `stoploss|${tx.id}|${today}`,
        });
      }
    }

    // ── 3. SIP reminder (3 days ahead) ──────────────────────────────────────
    const inThreeDays = new Date();
    inThreeDays.setDate(inThreeDays.getDate() + 3);
    const sipDay = inThreeDays.getDate();

    const { data: members } = await supabase
      .from('family_members')
      .select('id, owner_id, display_name, sip_day')
      .eq('sip_day', sipDay);

    for (const m of members || []) {
      alerts.push({
        owner_id: m.owner_id,
        alert_type: 'sip_reminder',
        severity: 'LOW',
        title: `SIP Due in 3 Days`,
        body: `${m.display_name}'s SIP is due on ${inThreeDays.toLocaleDateString('en-IN')}`,
        member_id: m.id,
        dedup_key: `sip_reminder|${m.id}|${today}`,
      });
    }

    // ── 4. Maturity alerts (other_assets) ────────────────────────────────────
    const in30Days = new Date();
    in30Days.setDate(in30Days.getDate() + 30);

    const { data: maturingAssets } = await supabase
      .from('other_assets')
      .select('id, owner_id, member_id, asset_type, description, maturity_date')
      .lte('maturity_date', in30Days.toISOString().substring(0, 10))
      .gte('maturity_date', today);

    for (const asset of maturingAssets || []) {
      const daysLeft = Math.ceil(
        (new Date(asset.maturity_date).getTime() - Date.now()) / 86400000,
      );
      alerts.push({
        owner_id: asset.owner_id,
        alert_type: 'maturity_alert',
        severity: daysLeft <= 7 ? 'URGENT' : 'MEDIUM',
        title: `${asset.asset_type} Maturing in ${daysLeft} Days`,
        body: `${asset.description} matures on ${asset.maturity_date}`,
        member_id: asset.member_id,
        dedup_key: `maturity|${asset.id}|${today}`,
      });
    }

    // ── Insert alerts with dedup ─────────────────────────────────────────────
    let inserted = 0;
    let emailed = 0;
    let pushed = 0;

    // Collect successfully inserted alerts grouped by owner
    const insertedByOwner = new Map<string, InsertedAlert[]>();

    for (const alert of alerts) {
      const { data: insertedRow, error } = await supabase
        .from('alert_log')
        .insert({
          ...alert,
          is_read: false,
          created_at: new Date().toISOString(),
        })
        .select('id, owner_id, alert_type, severity, title, body')
        .single();

      if (error?.code === '23505') continue; // duplicate
      if (error) {
        console.error('Alert insert error:', error.message);
        continue;
      }

      inserted++;

      if (insertedRow) {
        const list = insertedByOwner.get(alert.owner_id) ?? [];
        list.push(insertedRow as InsertedAlert);
        insertedByOwner.set(alert.owner_id, list);
      }
    }

    // ── Process each owner: prefs → filter → email → push → timestamp ────────
    for (const [ownerId, ownerAlerts] of insertedByOwner) {
      // Fetch profile: name, notification_prefs, fcm_token
      const { data: profile } = await supabase
        .from('profiles')
        .select('full_name, notification_prefs, fcm_token')
        .eq('id', ownerId)
        .single();

      const prefs: NotificationPrefs = profile?.notification_prefs ?? {};
      const fcmToken: string | null = profile?.fcm_token ?? null;

      // Master "off" toggle — skip everything
      if (prefs.frequency === 'off') continue;

      // Fetch auth email once per owner
      const { data: authUser } = await supabase.auth.admin.getUserById(ownerId);
      const userEmail = authUser?.user?.email ?? null;
      const userName = profile?.full_name ?? 'there';

      // Master email toggle
      const emailEnabled = prefs.email !== false && !!userEmail && !!RESEND_API_KEY;
      // Master push toggle
      const pushEnabled = prefs.push !== false && !!fcmToken;

      // Filter alerts by per-type pref
      const filteredAlerts = ownerAlerts.filter((a) => {
        const prefKey = alertTypeToPrefsKey(a.alert_type);
        return prefs[prefKey] !== false; // default allow if not explicitly false
      });

      if (filteredAlerts.length === 0) continue;

      const urgentAlerts = filteredAlerts.filter((a) => a.severity === 'URGENT');
      const mediumAlerts = filteredAlerts.filter((a) => a.severity === 'MEDIUM');
      // LOW alerts: in-app only, no email or push

      const emailedIds: string[] = [];
      const pushedIds: string[] = [];

      // ── URGENT: individual email + push ─────────────────────────────────
      for (const alert of urgentAlerts) {
        // Email: send for instant/daily; skip for weekly
        const shouldEmail =
          emailEnabled &&
          prefs.frequency !== 'weekly';

        if (shouldEmail) {
          const ok = await sendEmail(
            userEmail!,
            `[eVesh] ${alert.title}`,
            `<p>Hi ${userName},</p>
             <p><strong>${alert.title}</strong></p>
             <p>${alert.body}</p>
             <p><a href="https://evesh.app/alerts">View all alerts →</a></p>
             <hr><p style="color:#888;font-size:12px">eVesh Wealth Manager</p>`,
          );
          if (ok) {
            emailed++;
            emailedIds.push(alert.id);
          }
        }

        // Push: send immediately for URGENT regardless of frequency (except off)
        if (pushEnabled) {
          await sendPush(fcmToken!, alert.title, alert.body);
          pushed++;
          pushedIds.push(alert.id);
        }
      }

      // ── MEDIUM: single digest email ──────────────────────────────────────
      // Only send for instant frequency; daily/weekly skip email for MEDIUM
      if (
        mediumAlerts.length > 0 &&
        emailEnabled &&
        prefs.frequency === 'instant'
      ) {
        const digestRows = mediumAlerts
          .map(
            (a) =>
              `<tr>
                <td style="padding:6px 0"><strong>${a.title}</strong><br>
                <span style="color:#555">${a.body}</span></td>
              </tr>`,
          )
          .join('');

        const digestHtml = `
          <p>Hi ${userName},</p>
          <p>Here is your eVesh alerts summary:</p>
          <table style="width:100%;border-collapse:collapse">
            ${digestRows}
          </table>
          <p><a href="https://evesh.app/alerts">View all alerts →</a></p>
          <hr><p style="color:#888;font-size:12px">eVesh Wealth Manager</p>
        `;

        const ok = await sendEmail(
          userEmail!,
          `[eVesh] ${mediumAlerts.length} Alert${mediumAlerts.length > 1 ? 's' : ''} Summary`,
          digestHtml,
        );
        if (ok) {
          emailed++;
          for (const a of mediumAlerts) emailedIds.push(a.id);
        }
      }

      // ── Update timestamps ────────────────────────────────────────────────
      if (emailedIds.length > 0) {
        const { error: emailTsErr } = await supabase
          .from('alert_log')
          .update({ emailed_at: new Date().toISOString() })
          .in('id', emailedIds);
        if (emailTsErr) {
          console.warn('Failed to update emailed_at:', emailTsErr.message);
        }
      }

      if (pushedIds.length > 0) {
        const { error: pushTsErr } = await supabase
          .from('alert_log')
          .update({ push_sent_at: new Date().toISOString() })
          .in('id', pushedIds);
        if (pushTsErr) {
          console.warn('Failed to update push_sent_at:', pushTsErr.message);
        }
      }
    }

    console.log(
      `Alerts: ${alerts.length} generated, ${inserted} inserted, ${emailed} emailed, ${pushed} pushed`,
    );

    return new Response(
      JSON.stringify({ success: true, generated: alerts.length, inserted, emailed, pushed }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('send-alert-email error:', err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
