# eVesh Wealth Management — Data Audit & Standard Operating Procedure

> Last updated: 2026-03-28 | Maintainer: Nisanth

---

## 1. Executive Summary

In March 2026, a systematic audit of the eVesh tax calculation pipeline revealed a **Rs 45,000 gap** between CAMS registrar capital gains (Rs 1.66L) and eVesh FIFO estimates (Rs 1.21L) for FY 2025-26. The root cause was **corrupted FIFO lot queues** from duplicate transactions imported via two different sources (CAMS CAS PDF + MF Central Excel) that used incompatible deduplication hash formulas.

**Impact scope:**
- FIFO tax calculations produced incorrect STCG/LTCG classification per fund
- Total capital gains were understated by ~27%
- Portfolio unit balances were inflated for some funds
- CAMS vs eVesh comparison showed large unexplained per-fund differences

**Resolution:** Six bugs were identified and fixed. A single-source-of-truth architecture was enforced (CAMS CAS PDF only for transactions). This document captures all learnings, establishes the SOP for data management, and describes the automated audit system.

---

## 2. Bugs Found & Root Causes

### 2.1 Cross-Source Duplicate Transactions (CRITICAL)

**Symptom:** Doubled buy lots in FIFO queue, inflated portfolio units.

**Root cause:** Two import sources used different dedup hash formulas:
- CAMS CAS PDF: `SHA-256(ISIN | date | amount | txType | folio)`
- MF Central Excel: `SHA-256(fund_name | date | amount | txType | folio)`

The same transaction imported from both sources produced different hashes, bypassing the UNIQUE constraint on `dedup_hash`. This created two rows for the same buy, doubling the lots available for FIFO matching.

**Impact:** Extra lots shifted the entire FIFO queue. Earlier sells consumed the duplicate lots (with potentially different costs), leaving different lots for later sells. This changed both gain amounts and STCG/LTCG classification for subsequent sells.

**Fix:**
- CAMS CAS PDF import now **deletes ALL** `cams_cas_pdf` + `mfcentral_excel` transactions before re-inserting (clean slate)
- MF Central Excel import **disabled** in the app
- CAMS CAS PDF is the single source of truth for transactions

**Prevention:** Single-source architecture eliminates cross-source hash collisions entirely.

---

### 2.2 Gross vs Net Gain Comparison Bug (MEDIUM)

**Symptom:** CAMS vs eVesh comparison card showed CAMS total gain Rs 1.66L vs eVesh Rs 1.21L — a Rs 45K gap that was partly an apples-to-oranges comparison.

**Root cause:** CAMS `equityStcg`, `equityLtcg` etc. are **NET** figures (positive gains minus negative losses within each category). eVesh's comparison used `m.equityStcgGain` which is **GROSS** (positive gains only; losses stored separately in `equityStcgLoss`).

**Fix:** Comparison widget now computes NET from eVesh FIFO:
```
netEqStcg = m.equityStcgGain - m.equityStcgLoss
```

---

### 2.3 Cost Basis Formula Differences (MINOR)

**Symptom:** Small per-lot cost basis differences between CAMS and eVesh (~0.005% per transaction).

**Root cause:**
- eVesh uses `navAtTx` (purchase NAV from CAS) as cost per unit — excludes stamp duty (0.005%)
- CAMS "Unit Cost" may include stamp duty adjustments in certain scenarios

**Mitigation:** Difference is negligible (< Rs 1 per transaction). Documented as expected behavior. Acceptable within 2% tolerance.

---

### 2.4 FIFO Lot Order Corruption (CRITICAL — consequence of 2.1)

**Symptom:** Kotak Multicap showed STCG +Rs 12.7K higher, LTCG -Rs 63.4K lower than CAMS — net Rs 50K+ difference for a single fund.

**Root cause:** Duplicate buy lots from cross-source imports were inserted earlier in the FIFO queue. When sells were processed:
1. Earlier sells consumed the duplicate lots instead of the real ones
2. Later sells (e.g., Kotak Multicap) were matched against different lots
3. Lots that should have been LTCG (held >365 days) became STCG (newer duplicate lots)
4. Cost basis changed because duplicate lots had different `navAtTx` values

**Fix:** Eliminating duplicates via single-source import + clean re-import restores correct FIFO order.

---

### 2.5 Scheme Name Labeling Differences (LOW)

**Symptom:** Some funds showed as "Unmatched" in the CAMS vs eVesh comparison card.

**Root cause:** CAMS and MF Central use different scheme names for the same fund:
- CAMS: "Kotak Multicap Fund - Direct Plan - Growth"
- MFC: "Kotak Flexicap Fund - Direct Growth"

The fuzzy name matching (Jaccard word overlap at 30% threshold) sometimes fails when scheme names differ significantly.

**Mitigation:** Name matching is **display-only** for the comparison card. The underlying ISIN-based matching in transactions is authoritative. The comparison card now shows diagnostic info per fund (buy lot count, sell count, unmatched units) to help diagnose differences regardless of name matching quality.

---

### 2.6 `isRedemption => !isPurchase` Catch-All (DESIGN RISK)

**Symptom:** Potential for non-buy/non-sell transaction types (Dividend, Interest, Maturity) to be treated as sells in FIFO.

**Root cause:** `TransactionModel.isRedemption` was defined as `!isPurchase` — a negation of the purchase set. Any transaction type NOT in the explicit purchase list was treated as a redemption.

**Known purchase types:** BUY, SIP, Switch-In, STX-BUY, STP-In, Bonus, IDCW, Opening Balance
**Known sell types:** SELL, Switch-Out, STP-Out, SWP, STX-SELL
**Orphan types (incorrectly treated as sells):** Dividend, Interest, Maturity

**Fix:** Changed to explicit sell set:
```dart
bool get isRedemption => ['SELL','Switch-Out','STP-Out','SWP','STX-SELL'].contains(txType);
```
Non-buy/non-sell types are now ignored by both `isPurchase` and `isRedemption`.

---

## 3. What Worked

| Feature | Why It Worked |
|---------|---------------|
| CAMS CAS PDF as single source of truth | ISIN-based, registrar-grade data; eliminates cross-source hash collisions |
| `folio_details.closing_units` as registrar truth | Authoritative unit balance from CAMS; catches FIFO lot drift |
| FIFO calculator with grandfathering | Post-July 2024 Budget rules (12.5% LTCG, 20% STCG, Rs 1.25L exemption) correctly implemented |
| Capital loss offset (IT Act Sec 70-71) | ST losses offset STCG then LTCG; LT losses offset LTCG only; carry-forward tracking |
| Reconciliation provider | Folio unit validation catches data issues immediately post-import |
| Dedup hash UNIQUE constraint | Prevents exact duplicates within same source; first line of defense |
| Per-fund comparison card | Made the Rs 45K gap visible and diagnosable at the fund level |
| Diagnostic fields (buy lot count, sell count, unmatched units) | Immediately reveals data gaps per fund |

---

## 4. Standard Operating Procedure

### 4.1 Data Sources & Upload Order

| Step | Source                        | Target Table                     | Purpose                                 |
| ---- | ----------------------------- | -------------------------------- | --------------------------------------- |
| 1    | CAMS CAS PDF                  | `transactions` + `folio_details` | All buy/sell records since inception    |
| 2    | CAMS Tax XLSX or MFC Tax XLSX | `cams_tax_statements`            | Registrar-verified capital gains for FY |
| 3    | Manual entry (if needed)      | `transactions`                   | Non-MF assets (stocks, SGBs, FDs, etc.) |

**IMPORTANT:** Always upload CAS PDF **before** Tax XLSX. The CAS provides the transaction foundation; the Tax XLSX provides the verification layer.

---

### 4.2 Pre-Import Checklist

- [ ] Download latest CAMS CAS PDF from [mycams.camsonline.com](https://mycams.camsonline.com) or [camsonline.com](https://www.camsonline.com)
  - Select "Consolidated Account Statement" (not individual AMC)
  - Set "From" date to **earliest investment date** (e.g., 2015-01-01) for full history
  - Set "To" date to **today**
  - Select "Detailed Statement" format
- [ ] Download CAMS Capital Gains Statement XLSX for current FY from the same portal
- [ ] Verify family member setup in Settings > Family Members
  - Each member must have correct **PAN** (used to match CAS transactions to members)
  - Each member must have correct **Tax Slab %** (used for debt/gold STCG tax calculation)
- [ ] Note the PDF password format: `PAN + DOB` (e.g., `ABCDE1234F01-Jan-1990`)

---

### 4.3 Upload Steps

1. **Settings > Import Transactions (CAS)**
   - Select CAMS CAS PDF file
   - Enter PDF password when prompted
   - System auto-detects PAN and matches to family member
   - **The system deletes all prior `cams_cas_pdf` + `mfcentral_excel` transactions and re-imports from scratch** — this is safe and expected
   - Review import results: inserted, duplicates, errors
   - Check that all folios are matched to family members

2. **Settings > Import Tax Statement**
   - Upload CAMS or MFC Capital Gains XLSX
   - System parses scheme breakdowns and per-transaction FIFO lot matches
   - System UPSERTs into `cams_tax_statements` (overwrites prior data for same FY)

3. **Navigate to Tax screen**
   - Verify CAMS card shows correct total gains
   - Open CAMS vs eVesh comparison card — per-fund differences should be minimal
   - Check diagnostic row per fund: sell count should match, unmatched units should be 0

---

### 4.4 Post-Import Checklist

- [ ] **Dashboard**: Portfolio total value is reasonable (within 5% of expected)
- [ ] **Tax screen**: CAMS vs eVesh comparison total gain difference < Rs 5,000
- [ ] **Data Audit** (Settings > Data Audit): Run all 8 checks — all should PASS
- [ ] If unit mismatches exist: Re-download CAS PDF with wider date range (ensure full history)
- [ ] If unmatched sell units > 0: Missing historical buy data — re-download CAS from earlier date

---

### 4.5 Handling CAMS vs MFC Label Differences

CAMS and MF Central use different scheme naming conventions:

| Field | CAMS Convention | MFC Convention |
|-------|----------------|----------------|
| Scheme name | "Kotak Multicap Fund - Direct Plan - Growth" | "Kotak Flexicap Fund-Direct Growth" |
| ISIN included | Yes (embedded in scheme name) | Sometimes |
| Asset class | "EQUITY" / "OTHERS" | Not always split |

**Rules:**
1. **ISIN-based matching is authoritative** — used for transaction-to-fund linking
2. **Name matching is display-only** — used in comparison card for visual pairing
3. **If a fund shows as "Unmatched"** in comparison: it's a display issue, not a data issue
4. **Equity vs Non-Equity classification** uses heuristic scheme name matching — keywords like "liquid", "debt", "gilt", "overnight" classify as non-equity. Review `_isLikelyNonEquityScheme()` if classification seems wrong.

---

### 4.6 Data Wipe & Re-Import Protocol

**When to use:** When data integrity is compromised (duplicate sources, orphaned records, unexplained discrepancies).

**What gets deleted:**
| Table | Records Deleted | Can Be Restored From |
|-------|-----------------|---------------------|
| `cams_tax_statements` | All for your account | Re-upload Tax XLSX |
| `transactions` | ALL (including manual entries) | CAS PDF for MF; manual re-entry for non-MF |
| `folio_details` | All folio metadata | Re-upload CAS PDF |

**WARNING:** Manual entries (stocks, SGBs, FDs, PPF, NPS) are **NOT** restored by CAS import. You must re-enter them manually after the wipe.

**Steps:**
1. Settings > Wipe & Re-Import
2. Review preview (row counts per table)
3. Type "DELETE" to confirm
4. System deletes all data in order
5. Upload CAMS CAS PDF (rebuilds transactions + folios)
6. Upload Tax XLSX (rebuilds tax statements)
7. Re-enter manual transactions if needed
8. Run Data Audit to verify clean state

---

## 5. Automated Audit Checks

The app includes 8 automated data integrity checks accessible from **Settings > Data Audit**.

| # | Check | Severity | What It Detects |
|---|-------|----------|-----------------|
| 1 | Cross-source duplicates | ERROR | Same transaction from different import sources (ISIN+date+amount+type+folio) |
| 2 | Orphaned folios | WARNING | Folio records with closing_units > 0 but no matching transactions |
| 3 | Unit balance mismatch | ERROR | Computed units from transactions differ from CAMS registrar closing_units by > 2% |
| 4 | CAMS tax vs FIFO reconciliation | WARNING | Gain difference > Rs 1,000 or > 10% between CAMS tax statement and eVesh FIFO |
| 5 | Missing AMFI code mappings | WARNING | Transactions with ISIN but no amfi_code — cannot participate in FIFO or NAV lookup |
| 6 | Unmatched sell units | ERROR | Sell transactions that couldn't be matched to any buy lot — missing historical data |
| 7 | Transaction type safety | WARNING | Transactions with types not in known BUY or SELL sets (e.g., Dividend, Interest) |
| 8 | Folio-transaction ISIN consistency | WARNING | Folio ISIN doesn't match transaction ISIN for the same folio number |

**Interpretation:**
- **All PASS**: Data is clean and consistent
- **WARNING only**: Minor issues that may not affect calculations
- **Any ERROR**: Data integrity compromised — investigate and likely re-import

---

## 6. Known Limitations

1. **CAMS CAS PDF parsing** depends on CAMS's PDF layout consistency. If CAMS changes their statement format, the parser may need updates.

2. **Grandfathering** requires `jan_31_nav` in `fund_master` table. Not all funds have this value populated. Funds missing this NAV won't benefit from the grandfathering cost adjustment for pre-2018 holdings.

3. **Equity vs Non-Equity classification** for CAMS tax data uses heuristic keyword matching on scheme names. A fund could be misclassified if its name doesn't contain expected keywords. The `_isLikelyNonEquityScheme()` function should be reviewed periodically.

4. **Exit load parsing** from CAMS CAS is regex-based and may miss unusual formats (e.g., tiered exit loads with multiple conditions).

5. **Non-CAMS registrars** (KFintech): The app currently supports CAMS CAS statements only. Funds held with KFintech-registered AMCs won't appear in a CAMS CAS. Solution: Request a "Consolidated CAS" from MF Central which covers both registrars.

6. **MF Central Excel import is disabled** but legacy `mfcentral_excel` transactions may still exist in the database from prior imports. A data wipe clears these.

7. **The FIFO calculator processes funds independently** — it does not cross-reference FIFO lot matches across funds. Each `(memberId, amfiCode)` group is computed in isolation.

---

## 7. Architecture Decision Record

### ADR-001: Single Source of Truth for Transactions

**Decision:** CAMS CAS PDF is the sole source of truth for mutual fund transactions.

**Context:** Cross-source imports (CAMS + MFC) created duplicate transactions due to incompatible dedup hash formulas, corrupting the FIFO lot queue and producing incorrect capital gains.

**Consequences:**
- MF Central Excel import disabled in the app
- Re-importing CAS is a clean-slate operation (deletes old data first)
- Non-CAMS registrar funds require Consolidated CAS from MF Central
- No risk of cross-source hash collisions

### ADR-002: CAMS Tax Statement as Verification Layer

**Decision:** CAMS/MFC Tax XLSX provides the authoritative capital gains numbers. eVesh FIFO is supplementary.

**Context:** eVesh FIFO calculations will always have minor differences from CAMS due to cost basis rounding, lot ordering edge cases, and data coverage differences.

**Consequences:**
- When CAMS data exists, the CAMS card is the PRIMARY tax view
- eVesh FIFO card becomes secondary (collapsed by default, shows per-fund details only)
- Comparison card serves as reconciliation/debugging tool
- No competing headline gain/tax numbers

### ADR-003: Explicit Transaction Type Sets

**Decision:** Both `isPurchase` and `isRedemption` use explicit whitelists; unknown types are ignored.

**Context:** The original `isRedemption => !isPurchase` treated any non-purchase type as a sell, which would incorrectly include Dividend/Interest/Maturity in FIFO processing.

**Consequences:**
- Unknown transaction types are silently ignored in FIFO and portfolio calculations
- New transaction types must be explicitly added to the appropriate set
- Audit Check #7 flags any transactions with unknown types
