/**
 * Netlify Function: razorpay-webhook
 *
 * Handles Razorpay subscription webhook events and updates Supabase:
 *   - subscription.activated  → set subscription active + tier
 *   - subscription.charged    → renew expiry date
 *   - subscription.cancelled  → mark cancelled
 *   - subscription.completed  → mark completed
 *
 * Configure in Razorpay dashboard:
 *   Webhook URL: https://your-netlify-site.netlify.app/.netlify/functions/razorpay-webhook
 *   Secret: RAZORPAY_WEBHOOK_SECRET env variable
 */

const crypto = require('crypto');
const { createClient } = require('@supabase/supabase-js');

const RAZORPAY_WEBHOOK_SECRET = process.env.RAZORPAY_WEBHOOK_SECRET;
const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

// Map Razorpay plan IDs to subscription tiers
// Set these as env vars: PLAN_ID_INDIVIDUAL, PLAN_ID_FAMILY
const PLAN_TIER_MAP = {
  [process.env.PLAN_ID_INDIVIDUAL]: 'individual',
  [process.env.PLAN_ID_FAMILY]: 'family',
};

exports.handler = async (event) => {
  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, body: 'Method Not Allowed' };
  }

  // ── Verify Razorpay webhook signature ──────────────────────────────────────
  const signature = event.headers['x-razorpay-signature'];
  if (!RAZORPAY_WEBHOOK_SECRET || !signature) {
    return { statusCode: 401, body: 'Unauthorized' };
  }

  const expectedSig = crypto
    .createHmac('sha256', RAZORPAY_WEBHOOK_SECRET)
    .update(event.body)
    .digest('hex');

  if (!crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expectedSig))) {
    return { statusCode: 401, body: 'Invalid signature' };
  }

  const payload = JSON.parse(event.body);
  const eventType = payload.event;
  const subscription = payload.payload?.subscription?.entity;

  if (!subscription) {
    return { statusCode: 200, body: 'OK (no subscription entity)' };
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  try {
    switch (eventType) {
      case 'subscription.activated':
      case 'subscription.charged':
        await handleActivated(supabase, subscription, eventType);
        break;
      case 'subscription.cancelled':
      case 'subscription.completed':
      case 'subscription.expired':
        await handleCancelled(supabase, subscription, eventType);
        break;
      default:
        console.log(`Unhandled Razorpay event: ${eventType}`);
    }

    return { statusCode: 200, body: 'OK' };
  } catch (err) {
    console.error('Webhook processing error:', err);
    return { statusCode: 500, body: String(err) };
  }
};

async function handleActivated(supabase, sub, eventType) {
  const razorpaySubId = sub.id;
  const planId = sub.plan_id;
  const tier = PLAN_TIER_MAP[planId] ?? 'individual';

  // current_end is Unix timestamp (seconds)
  const expiresAt = sub.current_end
    ? new Date(sub.current_end * 1000).toISOString()
    : null;

  // Find or create subscription row matched by razorpay sub id or owner notes
  const ownerId = sub.notes?.owner_id;
  if (!ownerId) {
    console.warn('No owner_id in subscription notes — cannot link to user');
    return;
  }

  // Upsert subscription row
  await supabase.from('subscriptions').upsert({
    owner_id: ownerId,
    tier,
    status: 'active',
    payment_provider: 'razorpay',
    provider_sub_id: razorpaySubId,
    billing_cycle: sub.period ?? 'monthly',
    started_at: sub.start_at
      ? new Date(sub.start_at * 1000).toISOString()
      : new Date().toISOString(),
    expires_at: expiresAt,
  }, { onConflict: 'provider_sub_id' });

  // Update profile tier
  await supabase.from('profiles').update({
    subscription_tier: tier,
    subscription_status: 'active',
    subscription_expires_at: expiresAt,
  }).eq('id', ownerId);

  console.log(`Activated ${tier} for user ${ownerId} (event: ${eventType})`);
}

async function handleCancelled(supabase, sub, eventType) {
  const razorpaySubId = sub.id;

  // Look up the subscription by provider ID
  const { data: row } = await supabase
    .from('subscriptions')
    .select('owner_id')
    .eq('provider_sub_id', razorpaySubId)
    .maybeSingle();

  if (!row) {
    console.warn(`No subscription found for Razorpay ID ${razorpaySubId}`);
    return;
  }

  const status = eventType === 'subscription.expired' ? 'expired' : 'cancelled';

  await supabase.from('subscriptions').update({
    status,
  }).eq('provider_sub_id', razorpaySubId);

  // Downgrade profile to free
  await supabase.from('profiles').update({
    subscription_tier: 'free',
    subscription_status: status,
  }).eq('id', row.owner_id);

  console.log(`${status} subscription for user ${row.owner_id}`);
}
