# Spreadsheet Answers

## Cleaning Steps

The raw file `transactions_raw.csv` contained 30 rows and 10 columns. The following issues were identified and resolved:

1. **Whitespace** – Leading and trailing spaces were stripped from every column value.
2. **Merchant names** – Inconsistent casing (`ALPHA MART`, `alpha mart`, `Alpha  Mart`) and extra internal spaces were normalised by lowercasing, collapsing consecutive spaces, then mapping to the canonical title-case name from `merchant_master.csv`.
3. **Status values** – Contained mixed case (`Captured`, `CAPTURED`, `FAILED e05 TIMEOUT`, ` chargeback `) and descriptive error codes. All values were lowercased, stripped, and mapped: anything containing "captured" → `captured`; "chargeback" → `chargeback`; "failed", "e05", or "timeout" → `failed`.
4. **Risk scores** – Stored in formats such as `score:62`, `risk-83`, `75 `, and blank. A regex pattern extracted the first integer; blanks were recorded as `NaN`.
5. **Gateway region** – Mixed case (`apac`, ` APAC `, `eu`). Stripped and upper-cased; values not in the allowed set {APAC, EU, US} were treated as missing and back-filled from `merchant_master.default_region`.
6. **Currency conversion** – `raw_amount` values in INR, EUR, and USD were converted to USD by joining to `exchange_rates.csv` on `(transaction_date, currency)` and multiplying by the `usd_rate`. Result stored in `amount_usd` (rounded to 2 decimal places).
7. **Merchant enrichment** – `merchant_id`, `merchant_category`, and `account_manager` joined from `merchant_master.csv` on canonical `merchant_name`.

---

## Standardisation Rules

| Field | Raw Issue | Rule Applied |
|---|---|---|
| `merchant_name` | Mixed case, extra spaces | Lowercase → collapse whitespace → canonical map |
| `transaction_date` | Already ISO format | Parsed via `pd.to_datetime`, formatted as `YYYY-MM-DD` |
| `status` | Mixed case, E05 codes, trailing spaces | Lowercase + strip; keyword-based reclassification |
| `risk_score` | Prefixes `score:` / `risk-`, blanks | Regex extract first integer; blank → `NaN` |
| `gateway_region` | Mixed case, leading/trailing spaces, blanks | Uppercase + strip; fallback to `merchant_master.default_region` |
| `amount_usd` | INR / EUR / USD raw amounts | Multiply by daily USD rate from `exchange_rates.csv` |
| `high_value_flag` | New column | APAC > $5,000 / EU > $6,000 / US > $7,000 → 1, else 0 |
| `high_risk_flag` | New column | `risk_score ≥ 70` OR `status = 'chargeback'` → 1, else 0 |

---

## Lookup and Enrichment Logic

**Currency → USD conversion**
- Performed a date-aware lookup: `fx_rate = exchange_rates[(transaction_date, currency)]`
- `amount_usd = raw_amount × fx_rate`, rounded to 2 decimal places.
- All 30 rows had matching FX rates; no nulls in `amount_usd`.

**Merchant enrichment**
- `merchant_id`, `merchant_category`, `account_manager` were brought in via a `VLOOKUP`-style join on `merchant_name` (after standardisation) against `merchant_master.csv`.

**Region back-fill**
- 8 transactions had a blank `gateway_region` after standardisation.
- These were filled with the merchant's `default_region` from `merchant_master.csv` (Alpha Mart → APAC, Beta Stores → APAC).

**high_value_flag logic**
```
IF gateway_region = "APAC" AND amount_usd > 5000  → 1
IF gateway_region = "EU"   AND amount_usd > 6000  → 1
IF gateway_region = "US"   AND amount_usd > 7000  → 1
ELSE → 0
```

**high_risk_flag logic**
```
IF risk_score >= 70 OR status = "chargeback" → 1
ELSE → 0
```

---

## Final Answers

| Metric | Value |
|---|---|
| Total raw rows | 30 |
| Total cleaned rows | 30 |
| Invalid or missing rows handled | 0 rows dropped; issues fixed in-place (see cleaning steps) |
| Top region by GMV | **APAC** (USD 116,479.00) |
| Number of high value transactions | **7** |
| Number of high risk transactions | **9** |
| Top merchant by captured GMV | **Beta Stores** (USD 33,431.00) |

**Additional breakdown:**

| Status | Count |
|---|---|
| captured | 19 |
| failed | 7 |
| chargeback | 4 |

---

## Formula Samples

The following Excel-style formulas were used in the workbook (Sheet: `Cleaned_Transactions`):

**Merchant name canonical lookup (XLOOKUP / INDEX-MATCH)**
```excel
=INDEX(merchant_master!A:A, MATCH(LOWER(TRIM(B2)), LOWER(merchant_master!B:B), 0))
```

**Amount USD conversion (date-aware)**
```excel
=C2 * XLOOKUP(A2 & D2, exchange_rates!A:A & exchange_rates!B:B, exchange_rates!C:C)
```

**high_value_flag**
```excel
=IF(OR(AND(L2="APAC", I2>5000), AND(L2="EU", I2>6000), AND(L2="US", I2>7000)), 1, 0)
```

**high_risk_flag**
```excel
=IF(OR(K2>=70, J2="chargeback"), 1, 0)
```

**Merchant risk summary – Captured GMV**
```excel
=SUMIF(Cleaned_Transactions!E:E, A2, Cleaned_Transactions!I:I)
```

**Chargeback ratio**
```excel
=IFERROR(D2/B2, 0)
```
