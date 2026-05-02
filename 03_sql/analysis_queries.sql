-- ============================================================
-- QuickPay FinTech Operations – SQL Business Analysis
-- File: 03_sql/analysis_queries.sql
-- Database: cleaned_transactions (30 rows)
-- All queries are compatible with SQLite / PostgreSQL / MySQL
-- ============================================================

-- Q1
-- Count transactions by status
SELECT
    status,
    COUNT(*) AS transaction_count
FROM cleaned_transactions
GROUP BY status
ORDER BY transaction_count DESC;

-- Q2
-- Calculate total captured GMV by merchant
SELECT
    merchant_name,
    merchant_id,
    SUM(amount_usd) AS total_captured_gmv_usd
FROM cleaned_transactions
WHERE status = 'captured'
GROUP BY merchant_name, merchant_id
ORDER BY total_captured_gmv_usd DESC;

-- Q3
-- Show top 10 merchants by captured GMV
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

-- Q4
-- Show daily GMV and successful (captured) transaction count
SELECT
    transaction_date,
    SUM(amount_usd)                                          AS total_gmv_usd,
    SUM(CASE WHEN status = 'captured' THEN amount_usd END)  AS captured_gmv_usd,
    COUNT(*)                                                 AS total_transactions,
    SUM(CASE WHEN status = 'captured' THEN 1 ELSE 0 END)    AS captured_transaction_count
FROM cleaned_transactions
GROUP BY transaction_date
ORDER BY transaction_date;

-- Q5
-- Find merchants with chargeback ratio above 1%
SELECT
    merchant_name,
    merchant_id,
    COUNT(*)                                                        AS total_transactions,
    SUM(CASE WHEN status = 'chargeback' THEN 1 ELSE 0 END)         AS chargeback_count,
    ROUND(
        100.0 * SUM(CASE WHEN status = 'chargeback' THEN 1 ELSE 0 END)
        / COUNT(*), 2
    )                                                               AS chargeback_ratio_pct
FROM cleaned_transactions
GROUP BY merchant_name, merchant_id
HAVING chargeback_ratio_pct > 1
ORDER BY chargeback_ratio_pct DESC;

-- Q6
-- Find regions with average risk score above 50 and more than 20 transactions
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

-- Q7
-- Find users with 3 or more failed or chargeback transactions on the same day
SELECT
    user_id,
    transaction_date,
    COUNT(*) AS failed_or_chargeback_count
FROM cleaned_transactions
WHERE status IN ('failed', 'chargeback')
GROUP BY user_id, transaction_date
HAVING COUNT(*) >= 3
ORDER BY failed_or_chargeback_count DESC, transaction_date;

-- Q8
-- Show chargeback count, unique affected users, and chargeback amount by merchant
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
