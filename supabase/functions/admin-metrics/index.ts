/**
 * eVesh — Supabase Edge Function: admin-metrics
 *
 * Returns aggregate platform metrics: user counts, tier breakdown,
 * DAU/WAU/MAU, transaction volume, and subscription revenue.
 *
 * Requires: profiles.role = 'admin' (checked via JWT custom claim or DB lookup)
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

serve(async (req) => {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  };

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Verify caller is admin
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

    // Verify JWT and check admin role
    const token = authHeader.replace('Bearer ', '');
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { data: profile } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .single();

    if (profile?.role !== 'admin') {
      return new Response(JSON.stringify({ error: 'Forbidden' }), {
        status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const now = new Date();
    const dayAgo = new Date(now.getTime() - 86400000).toISOString();
    const weekAgo = new Date(now.getTime() - 7 * 86400000).toISOString();
    const monthAgo = new Date(now.getTime() - 30 * 86400000).toISOString();

    // Run all queries in parallel
    const [
      { count: totalUsers },
      { data: tierBreakdown },
      { count: dauCount },
      { count: wauCount },
      { count: mauCount },
      { count: totalTransactions },
      { data: revenueData },
      { data: newUsersThisWeek },
    ] = await Promise.all([
      supabase.from('profiles').select('*', { count: 'exact', head: true }),
      supabase.from('profiles').select('subscription_tier').eq('subscription_status', 'active'),
      supabase.from('profiles').select('*', { count: 'exact', head: true })
        .gte('updated_at', dayAgo),
      supabase.from('profiles').select('*', { count: 'exact', head: true })
        .gte('updated_at', weekAgo),
      supabase.from('profiles').select('*', { count: 'exact', head: true })
        .gte('updated_at', monthAgo),
      supabase.from('transactions').select('*', { count: 'exact', head: true }),
      supabase.from('subscriptions').select('amount_inr, tier')
        .eq('status', 'active'),
      supabase.from('profiles').select('subscription_tier, created_at')
        .gte('created_at', weekAgo)
        .order('created_at', { ascending: false }),
    ]);

    // Compute tier breakdown
    const tierCounts = { free: 0, individual: 0, family: 0 };
    for (const p of tierBreakdown || []) {
      const t = p.subscription_tier as keyof typeof tierCounts;
      if (t in tierCounts) tierCounts[t]++;
    }

    // MRR
    const mrr = (revenueData || []).reduce(
      (sum: number, s: any) => sum + (s.amount_inr || 0),
      0
    );

    return new Response(
      JSON.stringify({
        users: {
          total: totalUsers,
          dau: dauCount,
          wau: wauCount,
          mau: mauCount,
          tierBreakdown: tierCounts,
          newThisWeek: newUsersThisWeek?.length ?? 0,
        },
        transactions: { total: totalTransactions },
        revenue: { mrr },
        generatedAt: now.toISOString(),
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (err) {
    console.error('admin-metrics error:', err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
