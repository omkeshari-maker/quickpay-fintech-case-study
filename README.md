# QuickPay FinTech Operations – Case Study Submission

## Student Information

| Field | Value |
|---|---|
| **Student Name** | [Your Full Name] |
| **Student ID** | [Your Student ID] |
| **Public GitHub Repository** | [https://github.com/yourusername/quickpay-fintech-case-study](https://github.com/yourusername/quickpay-fintech-case-study) |

---

## Project Overview

This repository contains the complete submission for the **QuickPay FinTech Operations Case Study**, covering five analytical tasks:

| Part | Task | Tools |
|---|---|---|
| 1 | Spreadsheet Cleaning & Business Logic | Python (Pandas, openpyxl) → Excel |
| 2 | SQL Business Analysis | SQL (SQLite-compatible) |
| 3 | Python Reconciliation Workflow | Python / Pandas |
| 4 | JSON Normalization | Python / Pandas |
| 5 | Dashboard Visualization | Looker Studio |

---

## How to Run

### Prerequisites
```bash
pip install pandas openpyxl numpy
```

### Step 1 – Place raw data files
Ensure all raw files are in `01_data/raw/`:
```
transactions_raw.csv  merchant_master.csv  users.csv
ledger.csv            gateway.csv          exchange_rates.csv
api_response_sample.json
```

### Step 2 – Run the Python pipeline
Open and run all cells in `04_python/fintech_pipeline.ipynb` using Jupyter Notebook or JupyterLab:
```bash
jupyter notebook 04_python/fintech_pipeline.ipynb
```

All output files will be written to `01_data/processed/` and `04_python/`.

### Step 3 – Review the spreadsheet
Open `02_spreadsheet/spreadsheet_workbook.xlsx` in Microsoft Excel or Google Sheets.  
It contains 7 sheets: Cleaned_Transactions, Merchant_Risk_Summary, Daily_Summary, Payment_Method_Breakdown, Region_Breakdown, Exchange_Rates, and Standardisation_Rules.

### Step 4 – Review SQL queries
Open `03_sql/analysis_queries.sql` in any SQL editor.  
Queries are compatible with SQLite, PostgreSQL, and MySQL.  
Table name assumed: `cleaned_transactions`.

### Step 5 – View the dashboard
Open the Looker Studio dashboard link in `05_visualization/dashboard_link.txt`.

---

## Repository Structure

```
quickpay-fintech-case-study/
├── README.md
├── 01_data/
│   ├── raw/
│   │   ├── transactions_raw.csv
│   │   ├── merchant_master.csv
│   │   ├── users.csv
│   │   ├── ledger.csv
│   │   ├── gateway.csv
│   │   ├── exchange_rates.csv
│   │   └── api_response_sample.json
│   └── processed/
│       ├── cleaned_transactions.csv
│       ├── merchant_risk_summary.csv
│       ├── missing_in_gateway.csv
│       ├── missing_in_ledger.csv
│       ├── amount_mismatches.csv
│       ├── status_mismatches.csv
│       ├── reconciliation_report.csv
│       ├── api_normalized.csv
│       ├── daily_summary.csv
│       ├── payment_method_breakdown.csv
│       ├── region_breakdown.csv
│       └── merchant_performance_summary.csv
├── 02_spreadsheet/
│   ├── spreadsheet_workbook.xlsx
│   └── spreadsheet_answers.md
├── 03_sql/
│   ├── analysis_queries.sql
│   └── sql_answers.md
├── 04_python/
│   ├── fintech_pipeline.ipynb
│   └── summary_metrics.json
└── 05_visualization/
    └── dashboard_link.txt
```

---

## Key Findings Summary

### Data Cleaning (Part 1)
- **30 raw rows** → **30 cleaned rows** (no rows dropped; all issues fixed in-place)
- **Top region by GMV:** APAC (USD 116,479)
- **High-value transactions:** 7
- **High-risk transactions:** 9
- **Top merchant by captured GMV:** Beta Stores (USD 33,431)

### SQL Analysis (Part 2)
- **Captured transactions:** 19 | **Failed:** 7 | **Chargeback:** 4
- **All 5 merchants** exceed the 1% chargeback threshold
- **APAC** is the only region with avg risk > 50 and > 20 transactions (avg: 65.48)
- **User U008** had 4 failed/chargeback transactions on 2026-03-05 — high fraud risk

### Reconciliation (Part 3)
- **Total ledger records:** 10 | **Gateway records:** 9
- **Missing in gateway:** 2 (R004, R010)
- **Missing in ledger:** 1 (R011)
- **Amount mismatches:** 2 (R002: $50 diff, R008: $40 diff)
- **Status mismatches:** 1 (R005: ledger=success, gateway=failed)
- **Total amount at risk:** USD 7,890.00

### JSON Normalization (Part 4)
- 2 batches, 6 settlements flattened into tabular format
- Fields extracted: batch, merchant, settlement, bank details, timestamps

---

## Tools Used

| Tool | Purpose |
|---|---|
| Python 3.12 | Data pipeline, reconciliation, JSON normalization |
| Pandas | Data manipulation and aggregation |
| openpyxl | Excel workbook creation with formatting |
| SQL (SQLite syntax) | Business analysis queries |
| Jupyter Notebook | Interactive pipeline documentation |
| Looker Studio | Business monitoring dashboard |
| Git / GitHub | Version control and submission |
