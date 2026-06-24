# Data Model

## 1. Overview

The data model represents a simplified Invoice-to-Payment process within an Accounts Payable environment.

It combines master data, transaction data, payment data, exception classifications, and timestamped process events. The model is designed to support SQL-based analysis of invoice processing performance, payment execution, exception handling, vendor performance, department bottlenecks, process variants, and data quality.

The central analytical object is the invoice. Each invoice is linked to a vendor, an internal department, optionally to a purchase order, and to a set of process events that document the invoice workflow over time.

## 2. Model Design Principles

The model follows several design principles:

* Separate master data from transactional data.
* Use primary keys to uniquely identify each record.
* Use foreign keys to enforce valid relationships between entities.
* Keep invoice, payment, purchase order, and event-log data in separate tables.
* Allow invoice exceptions to be modeled explicitly.
* Use process events with timestamps to enable process mining style analysis.
* Preserve optional purchase order references to represent non-PO invoice scenarios.
* Support both operational reporting and process performance analysis.

## 3. Core Tables

The database consists of seven core tables:

* `vendors`
* `departments`
* `exception_types`
* `purchase_orders`
* `invoices`
* `payments`
* `invoice_events`

## 4. Entity Relationship Overview

```text id="tmzsb8"
vendors
  ├──< purchase_orders
  └──< invoices

departments
  ├──< purchase_orders
  ├──< invoices
  └──< invoice_events

exception_types
  └──< invoices

purchase_orders
  └──< invoices

invoices
  ├──< payments
  └──< invoice_events
```

The model uses `invoices` as the central transaction table. Most reporting and process analysis begins with this entity.

## 5. Vendors

The `vendors` table stores supplier master data.

| Column               | Data Type      | Key / Constraint        | Description                                      |
| -------------------- | -------------- | ----------------------- | ------------------------------------------------ |
| `vendor_id`          | `INT`          | Primary Key             | Unique identifier for each vendor                |
| `vendor_name`        | `VARCHAR(100)` | `NOT NULL`              | Legal or operational name of the vendor          |
| `country`            | `VARCHAR(50)`  | `NOT NULL`              | Country where the vendor is registered           |
| `vendor_category`    | `VARCHAR(50)`  | `NOT NULL`              | Type of product or service supplied              |
| `payment_terms_days` | `INT`          | `NOT NULL`, `CHECK > 0` | Agreed payment term in days                      |
| `risk_level`         | `VARCHAR(20)`  | `NOT NULL`              | Vendor risk classification: Low, Medium, or High |

### Purpose

This table supports:

* Vendor invoice volume analysis
* Vendor exception-rate analysis
* Vendor open-invoice exposure
* Vendor risk classification
* Vendor-specific process duration analysis

### Relationship Logic

One vendor can:

* Have multiple purchase orders
* Issue multiple invoices

## 6. Departments

The `departments` table stores internal business units involved in the Invoice-to-Payment process.

| Column            | Data Type      | Key / Constraint     | Description                                 |
| ----------------- | -------------- | -------------------- | ------------------------------------------- |
| `department_id`   | `INT`          | Primary Key          | Unique identifier for each department       |
| `department_name` | `VARCHAR(100)` | `NOT NULL`           | Department name                             |
| `cost_center`     | `VARCHAR(20)`  | `NOT NULL`, `UNIQUE` | Internal cost center code                   |
| `department_type` | `VARCHAR(50)`  | `NOT NULL`           | Functional classification of the department |

### Purpose

Departments are included to assign ownership and operational responsibility.

This table supports:

* Department-level invoice workload analysis
* Approval bottleneck analysis
* Event workload analysis
* Open invoice exposure by department
* Process duration analysis by responsible department

### Relationship Logic

One department can:

* Own multiple purchase orders
* Be responsible for multiple invoices
* Handle multiple invoice process events

## 7. Exception Types

The `exception_types` table defines the categories of invoice processing exceptions.

| Column                     | Data Type      | Key / Constraint         | Description                                     |
| -------------------------- | -------------- | ------------------------ | ----------------------------------------------- |
| `exception_type_id`        | `INT`          | Primary Key              | Unique identifier for an exception type         |
| `exception_name`           | `VARCHAR(100)` | `NOT NULL`               | Name of the exception                           |
| `exception_category`       | `VARCHAR(100)` | `NOT NULL`               | Higher-level classification of the issue        |
| `standard_resolution_days` | `INT`          | `NOT NULL`, `CHECK >= 0` | Expected resolution time for the exception type |

### Included Exception Types

The synthetic dataset includes:

* Missing Purchase Order
* Price Mismatch
* Quantity Mismatch
* Missing Approval
* Duplicate Invoice Suspected
* Incorrect Vendor Data

### Purpose

This table supports:

* Exception frequency analysis
* Exception impact analysis
* Exception resolution time analysis
* Identification of repeated process failures
* Prioritization of exception categories

### Relationship Logic

One exception type can be associated with multiple invoices.

An invoice may have no exception type because not every invoice follows a non-standard process.

## 8. Purchase Orders

The `purchase_orders` table stores purchase order header information.

| Column          | Data Type       | Key / Constraint        | Description                                              |
| --------------- | --------------- | ----------------------- | -------------------------------------------------------- |
| `po_id`         | `INT`           | Primary Key             | Unique identifier for each purchase order                |
| `vendor_id`     | `INT`           | Foreign Key             | References the vendor associated with the purchase order |
| `department_id` | `INT`           | Foreign Key             | References the department owning the purchase order      |
| `po_date`       | `DATE`          | `NOT NULL`              | Date when the purchase order was created                 |
| `po_amount`     | `DECIMAL(12,2)` | `NOT NULL`, `CHECK > 0` | Total value of the purchase order                        |
| `po_status`     | `VARCHAR(20)`   | `NOT NULL`              | Purchase order status: Open, Closed, or Cancelled        |

### Purpose

Purchase orders provide the reference point for invoice matching and variance analysis.

This table supports:

* Invoice-to-PO matching
* Invoice-to-PO amount comparison
* Purchase order utilization analysis
* Vendor and department procurement analysis
* Detection of invoices without valid purchase order references

### Relationship Logic

Each purchase order belongs to:

* One vendor
* One department

One purchase order may be linked to multiple invoices. This reflects the possibility of multiple invoice submissions, staged billing, or repeated supplier billing activity.

## 9. Invoices

The `invoices` table is the central transaction table in the model.

| Column              | Data Type       | Key / Constraint        | Description                                           |
| ------------------- | --------------- | ----------------------- | ----------------------------------------------------- |
| `invoice_id`        | `INT`           | Primary Key             | Unique identifier for each invoice                    |
| `vendor_id`         | `INT`           | Foreign Key, `NOT NULL` | References the invoice issuer                         |
| `po_id`             | `INT`           | Foreign Key, optional   | References the related purchase order                 |
| `department_id`     | `INT`           | Foreign Key, `NOT NULL` | References the department responsible for the invoice |
| `invoice_number`    | `VARCHAR(50)`   | `UNIQUE`, `NOT NULL`    | Vendor invoice reference number                       |
| `invoice_date`      | `DATE`          | `NOT NULL`              | Invoice issue date                                    |
| `received_date`     | `DATE`          | `NOT NULL`              | Date the invoice was received                         |
| `invoice_amount`    | `DECIMAL(12,2)` | `NOT NULL`, `CHECK > 0` | Financial value of the invoice                        |
| `invoice_status`    | `VARCHAR(30)`   | `NOT NULL`              | Current invoice status                                |
| `exception_type_id` | `INT`           | Foreign Key, optional   | References the exception type if applicable           |

### Invoice Statuses

The model supports the following statuses:

* `Received`
* `In Review`
* `Approved`
* `Paid`
* `Rejected`

### Purpose

The invoices table supports:

* Invoice volume and value analysis
* Open invoice analysis
* Payment performance analysis
* Exception analysis
* Vendor performance analysis
* Department ownership analysis
* Purchase order matching analysis
* Process-cycle analysis

### Optional Purchase Order Reference

The `po_id` field is intentionally optional.

This allows the model to represent invoices that:

* Were received without a purchase order
* Cannot be matched to an existing purchase order
* Require manual review before further processing

Such cases are relevant to Accounts Payable process analysis because they often create exception workflows and processing delays.

## 10. Payments

The `payments` table stores planned and actual payment information.

| Column                   | Data Type       | Key / Constraint         | Description                              |
| ------------------------ | --------------- | ------------------------ | ---------------------------------------- |
| `payment_id`             | `INT`           | Primary Key              | Unique identifier for the payment record |
| `invoice_id`             | `INT`           | Foreign Key, `NOT NULL`  | References the invoice being paid        |
| `scheduled_payment_date` | `DATE`          | `NOT NULL`               | Internally planned payment date          |
| `actual_payment_date`    | `DATE`          | Optional                 | Actual payment execution date            |
| `payment_amount`         | `DECIMAL(12,2)` | `NOT NULL`, `CHECK >= 0` | Amount paid                              |
| `payment_status`         | `VARCHAR(20)`   | `NOT NULL`               | Payment status: Open, Paid, or Cancelled |

### Purpose

The payments table supports:

* Open invoice exposure analysis
* Payment timing analysis
* Late payment identification
* Payment-delay calculation
* Vendor payment-performance analysis
* Financial risk monitoring

### Relationship Logic

The current project model assumes one payment record per invoice.

This is a deliberate simplification. It makes payment status and payment delay analysis easier to interpret. In a larger production model, one invoice could be linked to multiple payment records to support partial payments.

## 11. Invoice Events

The `invoice_events` table is the process event log used for workflow analysis.

| Column            | Data Type      | Key / Constraint        | Description                                          |
| ----------------- | -------------- | ----------------------- | ---------------------------------------------------- |
| `event_id`        | `INT`          | Primary Key             | Unique identifier for each process event             |
| `invoice_id`      | `INT`          | Foreign Key, `NOT NULL` | References the invoice associated with the event     |
| `event_name`      | `VARCHAR(100)` | `NOT NULL`              | Name of the process event                            |
| `event_timestamp` | `DATETIME`     | `NOT NULL`              | Date and time when the event occurred                |
| `department_id`   | `INT`          | Foreign Key, `NOT NULL` | Department responsible for the event                 |
| `event_status`    | `VARCHAR(20)`  | `NOT NULL`              | Status of the event: Completed, Pending, or Rejected |

### Supported Event Names

The model includes the following event types:

```text id="olnvz2"
Invoice Received
Data Validation
PO Matching
Exception Raised
Correction Requested
Correction Received
Approval
Approval Rejected
Rework
Payment Scheduled
Paid
```

### Purpose

The event log supports:

* Event sequence analysis
* Process variant analysis
* Step duration calculation
* Bottleneck identification
* SLA compliance analysis
* Exception resolution analysis
* Open-case monitoring
* Approval waiting-time analysis

### Relationship Logic

One invoice can have multiple process events.

The events are ordered by `event_timestamp`. This allows the project to reconstruct how each invoice moved through the Invoice-to-Payment process.

## 12. Relationship Summary

| Parent Entity     | Child Entity      | Relationship         | Business Meaning                                      |
| ----------------- | ----------------- | -------------------- | ----------------------------------------------------- |
| `vendors`         | `purchase_orders` | 1:n                  | A vendor can receive multiple purchase orders         |
| `vendors`         | `invoices`        | 1:n                  | A vendor can issue multiple invoices                  |
| `departments`     | `purchase_orders` | 1:n                  | A department can own multiple purchase orders         |
| `departments`     | `invoices`        | 1:n                  | A department can own multiple invoices                |
| `departments`     | `invoice_events`  | 1:n                  | A department can process many workflow events         |
| `exception_types` | `invoices`        | 1:n                  | An exception type can occur on multiple invoices      |
| `purchase_orders` | `invoices`        | 1:n                  | One purchase order can be linked to multiple invoices |
| `invoices`        | `payments`        | 1:1 in current model | Each invoice has one payment record                   |
| `invoices`        | `invoice_events`  | 1:n                  | Each invoice can have multiple process events         |

## 13. Data Integrity Controls

The schema includes several integrity controls.

### Primary Keys

Primary keys uniquely identify each record in the database.

Examples include:

* `vendor_id`
* `department_id`
* `po_id`
* `invoice_id`
* `payment_id`
* `event_id`

### Foreign Keys

Foreign keys ensure that referenced records exist before related records can be inserted.

Examples include:

* `invoices.vendor_id` references `vendors.vendor_id`
* `invoices.po_id` references `purchase_orders.po_id`
* `payments.invoice_id` references `invoices.invoice_id`
* `invoice_events.invoice_id` references `invoices.invoice_id`

### Unique Constraints

The schema uses unique constraints to prevent duplicate business identifiers.

Examples include:

* `invoice_number`
* `cost_center`

### Check Constraints

Check constraints validate expected business values.

Examples include:

* Positive invoice and purchase order amounts
* Valid vendor risk levels
* Valid invoice statuses
* Valid payment statuses
* Valid event statuses
* Invoice receipt date not earlier than invoice date

### Indexes

Indexes are created on frequently joined columns to improve analytical query performance.

Examples include:

* Vendor references
* Department references
* Purchase order references
* Invoice references
* Event timestamps

## 14. Analytical Layer

The model is extended through reusable SQL views.

The views include:

* `vw_invoice_overview`
* `vw_payment_performance`
* `vw_process_step_durations`
* `vw_process_variants`
* `vw_process_cycle_times`
* `vw_vendor_performance`
* `vw_open_process_cases`

These views separate raw operational data from reusable analytical logic.

They support:

* Faster KPI development
* Consistent business definitions
* Cleaner final queries
* Reduced duplication of joins and calculations
* Improved maintainability of the analysis layer

## 15. Data Model Limitations

The model is intentionally simplified for a SQL portfolio project.

The following limitations apply:

* One payment record is used per invoice.
* Partial payments are not modeled.
* Multi-currency transactions are not included.
* Tax calculations are not included.
* Goods receipt data is not modeled separately.
* Multi-level approval logic is not included.
* Payment runs and bank file processing are not included.
* Invoice line items are not modeled.
* Purchase orders are represented at header level only.
* Actual vendor contractual due-date compliance is not calculated separately from internal payment scheduling.

## 16. Conclusion

The data model provides a structured and realistic foundation for analyzing an Invoice-to-Payment process.

It enables the project to connect financial transaction data with operational event data. This supports analysis beyond traditional invoice reporting by making process delays, exceptions, workflow variations, and bottlenecks visible through SQL.
