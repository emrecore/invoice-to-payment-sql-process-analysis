# Invoice-to-Payment Process Analysis with SQL

## Overview

This project analyzes an Invoice-to-Payment process using SQL. The objective is to identify processing delays, payment issues, exception cases, and operational bottlenecks within an Accounts Payable workflow.

The dataset is synthetic but designed to reflect realistic business data structures commonly found in finance operations.

## Business Context

Invoice processing is a critical finance process that connects procurement, accounting, vendors, and internal departments. Delays in validation, purchase order matching, approval, or payment can increase manual effort, reduce process transparency, and affect supplier relationships.

This project uses SQL to analyze these process inefficiencies and derive data-driven optimization insights.

## Process Scope

```text
Invoice Received
→ Data Validation
→ PO Matching
→ Approval
→ Payment Scheduled
→ Paid
```

Exception cases include issues such as price mismatches, missing purchase orders, approval delays, and incorrect vendor data.

## Data Model

The database consists of the following tables:

| Table             | Purpose                               |
| ----------------- | ------------------------------------- |
| `vendors`         | Vendor master data                    |
| `departments`     | Internal departments and cost centers |
| `purchase_orders` | Purchase order records                |
| `exception_types` | Classification of invoice exceptions  |
| `invoices`        | Invoice-level transaction data        |
| `payments`        | Scheduled and actual payment data     |
| `invoice_events`  | Event log for process analysis        |

## Key Analyses

The SQL analysis covers:

* Invoice processing performance
* Open and late payments
* Vendor exception patterns
* Department-level processing delays
* Process step durations
* Bottleneck identification
* Standard vs. exception process comparison
* Data quality checks

## SQL Skills Demonstrated

* Table creation and constraints
* Primary and foreign keys
* Joins
* Aggregations
* `CASE WHEN` logic
* Date calculations
* Common Table Expressions
* Subqueries
* Window functions
* Views
* KPI calculation
* Data quality checks
* Process analysis with event logs

## Repository Structure

```text
invoice-to-payment-sql-process-analysis/
│
├── README.md
│
├── sql/
│   ├── 01_create_tables.sql
│   ├── 02_insert_sample_data.sql
│   ├── 03_basic_queries.sql
│   ├── 04_joins_and_aggregations.sql
│   ├── 05_process_analysis.sql
│   ├── 06_data_quality_checks.sql
│   ├── 07_create_views.sql
│   └── 08_final_business_insights.sql
│
├── docs/
    ├── business_case.md
    ├── data_model.md
    ├── kpi_definitions.md
    └── insights_summary.md
```

## Business Value

This project demonstrates how SQL can be used to transform operational finance data into actionable process insights. The analysis supports better visibility into invoice handling, vendor-related exceptions, payment delays, and improvement opportunities within Accounts Payable operations.
