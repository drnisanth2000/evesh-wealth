// supabase/functions/fetch-fund-holdings/index.ts
// Fetches and caches fund holdings from Groww for a given AMFI code.
// 1. Resolves Groww slug (search API → cache in fund_master.groww_slug)
// 2. Fetches scheme page, extracts __NEXT_DATA__ holdings
// 3. Upserts into fund_holdings_cache

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

interface GrowwHolding {
  company_name: string
  corpus_per: number
  sector_name: string
  instrument_name: string
  rating: string
  market_value: number
  nature_name: string
}

interface FetchResult {
  amfi_code: number
  holdings_count: number
  fetched_at: string
  slug: string | null
  error?: string
}

Deno.serve(async (req) => {
  const supabase = createClient(supabaseUrl, supabaseServiceKey)

  let body: { amfi_code?: number; amfi_codes?: number[]; fund_name?: string }
  try {
    body = await req.json()
  } catch {
    return new Response(JSON.stringify({ error: 'Invalid JSON body' }), { status: 400 })
  }

  // Support single or batch mode
  const amfiCodes = body.amfi_codes ?? (body.amfi_code ? [body.amfi_code] : [])
  if (amfiCodes.length === 0) {
    return new Response(JSON.stringify({ error: 'amfi_code or amfi_codes required' }), { status: 400 })
  }

  const results: FetchResult[] = []

  for (const amfiCode of amfiCodes) {
    try {
      const result = await fetchAndCacheHoldings(supabase, amfiCode, body.fund_name)
      results.push(result)
    } catch (e) {
      results.push({
        amfi_code: amfiCode,
        holdings_count: 0,
        fetched_at: new Date().toISOString(),
        slug: null,
        error: String(e),
      })
    }

    // Rate limit: 500ms between Groww fetches
    if (amfiCodes.length > 1) {
      await new Promise(resolve => setTimeout(resolve, 500))
    }
  }

  return new Response(JSON.stringify({ results }))
})

async function fetchAndCacheHoldings(
  supabase: any,
  amfiCode: number,
  fundNameHint?: string,
): Promise<FetchResult> {
  const now = new Date().toISOString()

  // 1. Check for existing slug
  const { data: fundRow } = await supabase
    .from('fund_master')
    .select('groww_slug, fund_name')
    .eq('amfi_code', amfiCode)
    .single()

  let slug: string | null = fundRow?.groww_slug ?? null
  const fundName = fundNameHint ?? fundRow?.fund_name ?? ''

  // 2. Resolve slug via Groww search if needed
  if (!slug && fundName) {
    slug = await resolveGrowwSlug(fundName)
    if (slug) {
      await supabase
        .from('fund_master')
        .update({ groww_slug: slug })
        .eq('amfi_code', amfiCode)
    }
  }

  if (!slug) {
    return { amfi_code: amfiCode, holdings_count: 0, fetched_at: now, slug: null, error: 'Could not resolve Groww slug' }
  }

  // 3. Fetch scheme page
  const pageUrl = `https://groww.in/mutual-funds/${slug}`
  const resp = await fetch(pageUrl, {
    headers: {
      'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
      'Accept': 'text/html',
    },
  })

  if (!resp.ok) {
    return { amfi_code: amfiCode, holdings_count: 0, fetched_at: now, slug, error: `HTTP ${resp.status}` }
  }

  const html = await resp.text()

  // 4. Extract __NEXT_DATA__
  const holdings = extractHoldings(html)

  if (holdings.length === 0) {
    return { amfi_code: amfiCode, holdings_count: 0, fetched_at: now, slug, error: 'No holdings found in __NEXT_DATA__' }
  }

  // 5. Aggregate holdings by company_name (same company may appear
  //    multiple times with different instrument types: equity, debt, etc.)
  const aggregated = new Map<string, {
    sector_name: string | null
    corpus_pct: number
    instrument_name: string | null
    nature_name: string | null
    rating: string | null
    market_value: number
  }>()

  for (const h of holdings) {
    const name = (h.company_name ?? 'Unknown').trim()
    if (!name) continue
    const existing = aggregated.get(name)
    if (existing) {
      existing.corpus_pct += (h.corpus_per ?? 0)
      existing.market_value += (h.market_value ?? 0)
    } else {
      aggregated.set(name, {
        sector_name: h.sector_name ?? null,
        corpus_pct: h.corpus_per ?? 0,
        instrument_name: h.instrument_name ?? null,
        nature_name: h.nature_name ?? null,
        rating: h.rating ?? null,
        market_value: h.market_value ?? 0,
      })
    }
  }

  // 6. Delete old cache and insert aggregated rows
  await supabase
    .from('fund_holdings_cache')
    .delete()
    .eq('amfi_code', amfiCode)

  const rows = [...aggregated.entries()].map(([name, data]) => ({
    amfi_code: amfiCode,
    company_name: name,
    sector_name: data.sector_name,
    corpus_pct: Math.round(data.corpus_pct * 10000) / 10000, // 4 decimal places
    instrument_name: data.instrument_name,
    nature_name: data.nature_name,
    rating: data.rating,
    market_value: Math.round(data.market_value * 100) / 100,
    fetched_at: now,
  }))

  const { error: insertErr } = await supabase
    .from('fund_holdings_cache')
    .upsert(rows, { onConflict: 'amfi_code,company_name' })

  if (insertErr) {
    console.error('Insert error:', insertErr)
  }

  return { amfi_code: amfiCode, holdings_count: rows.length, fetched_at: now, slug }
}

async function resolveGrowwSlug(fundName: string): Promise<string | null> {
  try {
    // Clean fund name for search — remove plan/option suffixes
    const query = fundName
      .replace(/\s*-\s*(Direct|Regular)\s*Plan\s*/i, ' ')
      .replace(/\s*-\s*(Growth|IDCW|Dividend)\s*/i, '')
      .trim()
      .slice(0, 60)

    // Groww v3 global search API (v1 entity search is deprecated/empty)
    const searchUrl = `https://groww.in/v1/api/search/v3/query/global/st_query?q=${encodeURIComponent(query)}&size=5&page=0`
    const resp = await fetch(searchUrl, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
        'Accept': 'application/json',
      },
    })

    if (!resp.ok) return null

    const data = await resp.json()
    // v3 response: { data: { content: [ { search_id, entity_type, ... } ] } }
    const results = data?.data?.content ?? data?.content ?? []

    if (results.length === 0) return null

    // Find first result that is a mutual fund scheme
    const mfResult = results.find((r: any) =>
      r.entity_type === 'Scheme' || r.sub_entity_type === 'Scheme'
    ) ?? results[0]

    const slug = mfResult.search_id ?? mfResult.id ?? mfResult.url ?? null

    if (!slug) return null

    // Slug might be a full path like "/mutual-funds/xyz" — extract just the slug
    if (slug.startsWith('/mutual-funds/')) {
      return slug.replace('/mutual-funds/', '')
    }

    return slug
  } catch (e) {
    console.warn('Groww search failed:', e)
    return null
  }
}

function extractHoldings(html: string): GrowwHolding[] {
  try {
    // Find __NEXT_DATA__ script tag content
    const scriptStart = html.indexOf('<script id="__NEXT_DATA__"')
    if (scriptStart === -1) {
      // Try alternate pattern
      const altStart = html.indexOf('__NEXT_DATA__')
      if (altStart === -1) return []
    }

    // Extract JSON between <script> tags
    const jsonStart = html.indexOf('>', scriptStart) + 1
    const jsonEnd = html.indexOf('</script>', jsonStart)
    if (jsonStart <= 0 || jsonEnd <= jsonStart) return []

    const jsonStr = html.substring(jsonStart, jsonEnd).trim()
    const nextData = JSON.parse(jsonStr)

    // Navigate to holdings
    const holdings =
      nextData?.props?.pageProps?.mfServerSideData?.holdings ??
      nextData?.props?.pageProps?.holdings ??
      nextData?.props?.pageProps?.schemeData?.holdings ??
      []

    return holdings as GrowwHolding[]
  } catch (e) {
    console.warn('Failed to parse __NEXT_DATA__:', e)
    return []
  }
}
