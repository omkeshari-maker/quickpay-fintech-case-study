# SQL Answers

---

## Q1

### Query
```sql
SELECT
    status,
    COUNT(*) AS transaction_count
FROM cleaned_transactions
GROUP BY status
ORDER BY transaction_count DESC;
```

### Result Summary
There are 3 distinct statuses in the cleaned dataset (30 total transactions):

| status | transaction_count |
|---|---|
| captured | 19 |
| failed | 7 |
| chargeback | 4 |

**63.3%** of all transactions are successfully captured. Chargeback rate across the entire dataset is **13.3%** of non-captured (failed + chargeback) events.

---

## Q2

### Query
```sql
SELECT
    merchant_name,
    merchant_id,
    SUM(amount_usd) AS total_captured_gmv_usd
FROM cleaned_transactions
WHERE status = 'captured'
GROUP BY merchant_name, merchant_id
ORDER BY total_captured_gmv_usd DESC;
```

### Result Summary
Eco Home had **zero** captured transactions (its only transactions were a chargeback and a failed). The captured GMV hierarchy is:

| merchant_name | merchant_id | total_captured_gmv_usd |
|---|---|---|
| Beta Stores | M002 | 33,431.00 |
| Alpha Mart | M001 | 29,984.50 |
| Delta Travels | M004 | 10,300.00 |
| City Pharma | M003 | 8,640.00 |

**Total confirmed GMV across all merchants: USD 82,355.50**

---

## Q3

### Query
```sql
SELECT
    merchant_name,
    merchant_id,
    SUM(amount_usd)  AS captured_gmv_usd,
    COUNT(*)         AS captured_transaction_count
FROM cleaned_transactions
WHERE status = 'captured'
GROUP BY merchant_name, merchant_id
ORDER BY captured_gmv_usd DESC
LIMIT 10;
```

### Result Summary
The dataset contains only 4 merchants with captured transactions, so the top-10 list contains all of them:

| Rank | merchant_name | captured_gmv_usd | captured_tx_count |
|---|---|---|---|
| 1 | Beta Stores | 33,431.00 | 7 |
| 2 | Alpha Mart | 29,984.50 | 8 |
| 3 | Delta Travels | 10,300.00 | 2 |
| 4 | City Pharma | 8,640.00 | 2 |

Alpha Mart has the **highest number** of captured transactions (8), while Beta Stores leads in **total captured value** (USD 33,431).

---

## Q4

### Query
```sql
SELECT
    transaction_date,
    SUM(amount_usd)                                          AS total_gmv_usd,
    SUM(CASE WHEN status = 'captured' THEN amount_usd END)  AS captured_gmv_usd,
    COUNT(*)                                                 AS total_transactions,
    SUM(CASE WHEN status = 'captured' THEN 1 ELSE 0 END)    AS captured_transaction_count
FROM cleaned_transactions
GROUP BY transaction_date
ORDER BY transaction_date;
```

### Result Summary
| transaction_date | total_gmv_usd | captured_gmv_usd | total_transactions | captured_tx_count |
|---|---|---|---|---|
| 2026-03-01 | 26,382.00 | 26,382.00 | 5 | 5 |
| 2026-03-02 | 25,049.00 | 11,080.00 | 6 | 3 |
| 2026-03-03 | 18,391.00 | 16,031.50 | 5 | 4 |
| 2026-03-04 | 16,420.00 | 13,920.00 | 5 | 4 |
| 2026-03-05 | 19,232.00 | 6,136.00 | 6 | 1 |
| 2026-03-06 | 10,606.00 | 8,806.00 | 3 | 2 |

**2026-03-01** was a perfect day — 100% capture rate. **2026-03-05** had the worst day — only 1 out of 6 transactions captured (16.7%), driven by multiple failures and a chargeback for user U008.

---

## Q5

### Query
```sql
SELECT
    merchant_name,
    merchant_id,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN status = 'chargeback' THEN 1 ELSE 0 END) AS chargeback_count,
    ROUND(
        100.0 * SUM(CASE WHEN status = 'chargeback' THEN 1 ELSE 0 END)
        / COUNT(*), 2
    ) AS chargeback_ratio_pct
FROM cleaned_transactions
GROUP BY merchant_name, merchant_id
HAVING chargeback_ratio_pct > 1
ORDER BY chargeback_ratio_pct DESC;
```

### Result Summary
**All 5 merchants** exceed the 1% chargeback threshold (each has at least 1 chargeback):

| merchant_name | total_transactions | chargeback_count | chargeback_ratio_pct |
|---|---|---|---|
| Eco Home | 2 | 1 | 50.00% |
| Delta Travels | 4 | 1 | 25.00% |
| Beta Stores | 11 | 1 | 9.09% |
| Alpha Mart | 11 | 1 | 9.09% |

Eco Home and Delta Travels have extremely high chargeback ratios due to low transaction volumes. This represents a critical risk requiring investigation.

---

## Q6

### Query
```sql
SELECT
    gateway_region,
    COUNT(*)                  AS transaction_count,
    ROUND(AVG(risk_score), 2) AS avg_risk_score
FROM cleaned_transactions
WHERE risk_score IS NOT NULL
GROUP BY gateway_region
HAVING AVG(risk_score) > 50
   AND COUNT(*) > 20
ORDER BY avg_risk_score DESC;
```

### Result Summary
Only **APAC** satisfies both conditions (avg risk > 50 AND transaction count > 20):

| gateway_region | transaction_count | avg_risk_score |
|---|---|---|
| APAC | 21 | 65.48 |

EU (4 transactions, avg risk 46.75) and US (4 transactions, avg risk 48.75) both fail the "> 20 transactions" threshold. APAC requires enhanced monitoring given its elevated average risk score of 65.48.

---

## Q7

### Query
```sql
SELECT
    user_id,
    transaction_date,
    COUNT(*) AS failed_or_chargeback_count
FROM cleaned_transactions
WHERE status IN ('failed', 'chargeback')
GROUP BY user_id, transaction_date
HAVING COUNT(*) >= 3
ORDER BY failed_or_chargeback_count DESC, transaction_date;
```

### Result Summary
**1 user** triggered this alert:

| user_id | transaction_date | failed_or_chargeback_count |
|---|---|---|
| U008 | 2026-03-05 | 4 |

User **U008 (Ishaan Verma)** had 4 failed/chargeback transactions on a single day (2026-03-05): T016 (failed), T017 (failed), T018 (chargeback), T019 (failed) — across Beta Stores and Alpha Mart. This concentration of failures in a single user–day is a significant fraud risk signal.

---

## Q8

### Query
```sql
SELECT
    merchant_name,
    merchant_id,
    COUNT(*)              AS chargeback_count,
    COUNT(DISTINCT user_id) AS unique_affected_users,
    SUM(amount_usd)       AS total_chargeback_amount_usd
FROM cleaned_transactions
WHERE status = 'chargeback'
GROUP BY merchant_name, merchant_id
ORDER BY chargeback_count DESC;
```

### Result Summary
Each merchant has exactly 1 chargeback, affecting 1 unique user:

| merchant_name | merchant_id | chargeback_count | unique_affected_users | total_chargeback_amount_usd |
|---|---|---|---|---|
| Alpha Mart | M001 | 1 | 1 | 5,400.00 |
| Beta Stores | M002 | 1 | 1 | 1,711.00 |
| Delta Travels | M004 | 1 | 1 | 2,500.00 |
| Eco Home | M005 | 1 | 1 | 6,649.00 |

**Total chargeback exposure: USD 16,260.00**. Eco Home's single chargeback of $6,649 is the highest-value chargeback in the dataset. City Pharma (M003) had no chargebacks.
