# AMFI Scraper

Scrapes the AMFI scheme categorisation knowledge-center page and the AMFI list
of benchmark indices, then merges them into a single canonical catalog of the
SEBI 2018 mutual-fund categories with their tier-1 / tier-2 benchmarks.

## Sources

- https://www.amfiindia.com/investor/knowledge-center-info?zoneName=CategorizationOfMutualFundSchemes
- https://www.amfiindia.com/otherdata/listofbenchmarkindices?tab=equitySchemes

The benchmark page is a Next.js client-rendered table; we use Playwright
chromium with `page.waitForSelector('table tbody tr')`.

## Usage

```sh
npm install
npx playwright install chromium
npm run scrape    # writes out/amfi_categories.json
npm run gen:sql   # writes out/019_seed_amfi_categories.sql
npm run gen:dart  # writes ../../lib/core/constants/amfi_category.g.dart
```

`npm run all` runs all three.

## Hand-curation

The categorical metadata (`default_term`, `default_asset_class`,
`default_tax_category`) is hand-curated inside `scrape.ts` per SEBI 2018
circular SEBI/HO/IMD/DF3/CIR/P/2017/114, since these mappings rarely change.

If AMFI's HTML changes and scraping breaks, the curated table inside
`scrape.ts` is the source of truth and the network fetch only fills in the
benchmark indices column.
