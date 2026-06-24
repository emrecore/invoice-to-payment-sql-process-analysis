-- ============================================================
-- Project: Invoice-to-Payment Process Analysis with SQL
-- File: 03_basic_queries.sql
-- Purpose: Basic SQL queries using SELECT, WHERE, ORDER BY,
-- DISTINCT, LIMIT, and simple calculated columns.
-- SQL Dialect: MySQL
-- ============================================================

USE invoice_to_payment_analysis;

-- ============================================================
-- 1. View all vendors
-- Basic SELECT query.
-- ============================================================

SELECT
    vendor_id,
    vendor_name,
    country,
    vendor_category,
    payment_terms_days,
    risk_level
FROM vendors;

-- ============================================================
-- 2. View all departments
-- Basic SELECT query.
-- ============================================================

SELECT
    department_id,
    department_name,
    cost_center,
    department_type
FROM departments;

-- ============================================================
-- 3. View all invoices
-- Basic invoice overview.
-- ============================================================

SELECT
    invoice_id,
    vendor_id,
    po_id,
    department_id,
    invoice_number,
    invoice_date,
    received_date,
    invoice_amount,
    invoice_status,
    exception_type_id
FROM invoices;

-- ============================================================
-- 4. Find invoices awaiting payment approval or still under review
-- Demonstrates WHERE with OR.
-- COMMENT: "Approved" invoices are included because they may still
-- await payment, while "In Review" invoices are still being processed.
-- ============================================================

SELECT
    invoice_id,
    vendor_id,
    po_id,
    invoice_number,
    received_date,
    invoice_amount,
    invoice_status
FROM invoices
WHERE invoice_status = 'Approved'
   OR invoice_status = 'In Review'
ORDER BY received_date;

-- ============================================================
-- 5. Find all paid invoices
-- Demonstrates WHERE with equality condition.
-- ============================================================

SELECT
    invoice_id,
    invoice_number,
    invoice_date,
    received_date,
    invoice_amount,
    invoice_status
FROM invoices
WHERE invoice_status = 'Paid'
ORDER BY invoice_date;

-- ============================================================
-- 6. Find invoices above 5,000 EUR
-- Demonstrates numeric filtering.
-- ============================================================

SELECT
    invoice_id,
    invoice_number,
    invoice_amount,
    invoice_status
FROM invoices
WHERE invoice_amount > 5000
ORDER BY invoice_amount DESC;

-- ============================================================
-- 7. Find high-value invoices above 10,000 EUR
-- Demonstrates stronger numeric filtering.
-- ============================================================

SELECT
    invoice_id,
    vendor_id,
    po_id,
    invoice_number,
    invoice_amount,
    invoice_status
FROM invoices
WHERE invoice_amount > 10000
ORDER BY invoice_amount DESC;

-- ============================================================
-- 8. Find invoices between 2,500 and 7,500 EUR
-- Demonstrates BETWEEN.
-- ============================================================

SELECT
    invoice_id,
    invoice_number,
    invoice_amount,
    invoice_status
FROM invoices
WHERE invoice_amount BETWEEN 2500 AND 7500
ORDER BY invoice_amount;

-- ============================================================
-- 9. Find invoices received in January 2025
-- Demonstrates date filtering.
-- ============================================================

SELECT
    invoice_id,
    invoice_number,
    invoice_date,
    received_date,
    invoice_amount,
    invoice_status
FROM invoices
WHERE received_date BETWEEN '2025-01-01' AND '2025-01-31'
ORDER BY received_date;

-- ============================================================
-- 10. Find invoices received after February 1, 2025
-- Demonstrates date comparison.
-- ============================================================

SELECT
    invoice_id,
    invoice_number,
    received_date,
    invoice_amount,
    invoice_status
FROM invoices
WHERE received_date >= '2025-02-01'
ORDER BY received_date;

-- ============================================================
-- 11. Find invoices with an exception
-- Demonstrates IS NOT NULL.
-- ============================================================

SELECT
    invoice_id,
    invoice_number,
    invoice_amount,
    invoice_status,
    exception_type_id
FROM invoices
WHERE exception_type_id IS NOT NULL
ORDER BY invoice_id;

-- ============================================================
-- 12. Find invoices without an exception
-- Demonstrates IS NULL.
-- ============================================================

SELECT
    invoice_id,
    invoice_number,
    invoice_amount,
    invoice_status,
    exception_type_id
FROM invoices
WHERE exception_type_id IS NULL
ORDER BY invoice_id;

-- ============================================================
-- 13. Find invoices without a purchase order
-- Business case: missing PO reference.
-- ============================================================

SELECT
    invoice_id,
    vendor_id,
    po_id,
    invoice_number,
    invoice_amount,
    invoice_status
FROM invoices
WHERE po_id IS NULL;

-- ============================================================
-- 14. Find vendors with medium or high risk
-- Demonstrates IN.
-- ============================================================

SELECT
    vendor_id,
    vendor_name,
    country,
    vendor_category,
    risk_level
FROM vendors
WHERE risk_level IN ('Medium', 'High')
ORDER BY risk_level, vendor_name;

-- ============================================================
-- 15. Find vendors from Germany
-- Demonstrates text filtering.
-- ============================================================

SELECT
    vendor_id,
    vendor_name,
    country,
    vendor_category,
    risk_level
FROM vendors
WHERE country = 'Germany'
ORDER BY vendor_name;

-- ============================================================
-- 16. Find vendors whose name contains GmbH
-- Demonstrates LIKE.
-- ============================================================

SELECT
    vendor_id,
    vendor_name,
    country,
    vendor_category
FROM vendors
WHERE vendor_name LIKE '%GmbH%'
ORDER BY vendor_name;

-- ============================================================
-- 17. Show distinct vendor categories
-- Demonstrates DISTINCT.
-- ============================================================

SELECT DISTINCT
    vendor_category
FROM vendors
ORDER BY vendor_category;

-- ============================================================
-- 18. Show distinct invoice statuses
-- Demonstrates DISTINCT.
-- ============================================================

SELECT DISTINCT
    invoice_status
FROM invoices
ORDER BY invoice_status;

-- ============================================================
-- 19. Show the five largest invoices
-- Demonstrates ORDER BY and LIMIT.
-- ============================================================

SELECT
    invoice_id,
    invoice_number,
    invoice_amount,
    invoice_status
FROM invoices
ORDER BY invoice_amount DESC
LIMIT 5;

-- ============================================================
-- 20. Show the five earliest received invoices
-- Demonstrates date sorting and LIMIT.
-- ============================================================

SELECT
    invoice_id,
    invoice_number,
    received_date,
    invoice_amount,
    invoice_status
FROM invoices
ORDER BY received_date ASC
LIMIT 5;

-- ============================================================
-- 21. Calculate days between invoice date and received date
-- Demonstrates DATEDIFF.
-- ============================================================

SELECT
    invoice_id,
    invoice_number,
    invoice_date,
    received_date,
    DATEDIFF(received_date, invoice_date) AS days_until_received
FROM invoices
ORDER BY days_until_received DESC;

-- ============================================================
-- 22. Classify invoices by amount
-- Demonstrates CASE WHEN.
-- ============================================================

SELECT
    invoice_id,
    invoice_number,
    invoice_amount,
    CASE
        WHEN invoice_amount < 2500 THEN 'Small'
        WHEN invoice_amount BETWEEN 2500 AND 7500 THEN 'Medium'
        ELSE 'Large'
    END AS invoice_size_category
FROM invoices
ORDER BY invoice_amount DESC;

-- ============================================================
-- 23. Classify invoices by process type
-- Demonstrates CASE WHEN with NULL logic.
-- ============================================================

SELECT
    invoice_id,
    invoice_number,
    invoice_status,
    exception_type_id,
    CASE
        WHEN exception_type_id IS NULL THEN 'Standard Process'
        WHEN exception_type_id IS NOT NULL THEN 'Exception Process'
    END AS process_type
FROM invoices
ORDER BY invoice_id;

-- ============================================================
-- 24. Classify payments by payment timing
-- Demonstrates CASE WHEN with dates and NULL values.
-- ============================================================

SELECT
    payment_id,
    invoice_id,
    scheduled_payment_date,
    actual_payment_date,
    payment_amount,
    payment_status,
    CASE
        WHEN actual_payment_date IS NULL THEN 'Open'
        WHEN actual_payment_date < scheduled_payment_date THEN 'Paid Early'
        WHEN actual_payment_date = scheduled_payment_date THEN 'Paid On Time'
        WHEN actual_payment_date > scheduled_payment_date THEN 'Paid Late'
    END AS payment_timing
FROM payments
ORDER BY scheduled_payment_date;

-- ============================================================
-- 25. Calculate payment delay in days
-- Open payments return NULL as delay here.
-- ============================================================

SELECT
    payment_id,
    invoice_id,
    scheduled_payment_date,
    actual_payment_date,
    DATEDIFF(actual_payment_date, scheduled_payment_date) AS payment_delay_days
FROM payments
ORDER BY payment_delay_days DESC;

-- ============================================================
-- 26. Show only late payments
-- Demonstrates date comparison.
-- ============================================================

SELECT
    payment_id,
    invoice_id,
    scheduled_payment_date,
    actual_payment_date,
    DATEDIFF(actual_payment_date, scheduled_payment_date) AS payment_delay_days
FROM payments
WHERE actual_payment_date > scheduled_payment_date
ORDER BY payment_delay_days DESC;

-- ============================================================
-- 27. Show open payments
-- Demonstrates NULL filtering.
-- ============================================================

SELECT
    payment_id,
    invoice_id,
    scheduled_payment_date,
    actual_payment_date,
    payment_amount,
    payment_status
FROM payments
WHERE actual_payment_date IS NULL
ORDER BY scheduled_payment_date;

-- ============================================================
-- 28. Show completed process events
-- Basic filtering on event log.
-- ============================================================

SELECT
    event_id,
    invoice_id,
    event_name,
    event_timestamp,
    department_id,
    event_status
FROM invoice_events
WHERE event_status = 'Completed'
ORDER BY invoice_id, event_timestamp;

-- ============================================================
-- 29. Show pending process events
-- Business case: process items waiting for action.
-- ============================================================

SELECT
    event_id,
    invoice_id,
    event_name,
    event_timestamp,
    department_id,
    event_status
FROM invoice_events
WHERE event_status = 'Pending'
ORDER BY event_timestamp;

-- ============================================================
-- 30. Show events related to exceptions
-- Demonstrates IN with event names.
-- ============================================================

SELECT
    event_id,
    invoice_id,
    event_name,
    event_timestamp,
    department_id,
    event_status
FROM invoice_events
WHERE event_name IN (
    'Exception Raised',
    'Correction Requested',
    'Correction Received'
)
ORDER BY invoice_id, event_timestamp;

-- ============================================================
-- 31. Find events after February 1, 2025
-- Demonstrates DATETIME filtering.
-- ============================================================

SELECT
    event_id,
    invoice_id,
    event_name,
    event_timestamp,
    event_status
FROM invoice_events
WHERE event_timestamp >= '2025-02-01 00:00:00'
ORDER BY event_timestamp;

-- ============================================================
-- 32. Show purchase orders above 10,000 EUR
-- Basic filtering on purchase orders.
-- ============================================================

SELECT
    po_id,
    vendor_id,
    department_id,
    po_date,
    po_amount,
    po_status
FROM purchase_orders
WHERE po_amount > 10000
ORDER BY po_amount DESC;

-- ============================================================
-- 33. Show open purchase orders
-- Business case: open purchasing commitments.
-- ============================================================

SELECT
    po_id,
    vendor_id,
    department_id,
    po_date,
    po_amount,
    po_status
FROM purchase_orders
WHERE po_status = 'Open'
ORDER BY po_date;

-- ============================================================
-- 34. Calculate simple invoice amount category and status together
-- Demonstrates combined business classification.
-- ============================================================

SELECT
    invoice_id,
    invoice_number,
    invoice_amount,
    invoice_status,
    CASE
        WHEN invoice_amount < 2500 THEN 'Small'
        WHEN invoice_amount BETWEEN 2500 AND 7500 THEN 'Medium'
        ELSE 'Large'
    END AS invoice_size_category,
    CASE
        WHEN invoice_status IN ('Approved', 'In Review') THEN 'Open Process'
        WHEN invoice_status = 'Paid' THEN 'Completed Process'
        WHEN invoice_status = 'Rejected' THEN 'Rejected Process'
        ELSE 'Other'
    END AS process_status_category
FROM invoices
ORDER BY invoice_amount DESC;

-- ============================================================
-- 35. Show invoices that are both high value and not paid
-- Demonstrates AND.
-- ============================================================

SELECT
    invoice_id,
    invoice_number,
    invoice_amount,
    invoice_status
FROM invoices
WHERE invoice_amount > 7500
  AND invoice_status <> 'Paid'
ORDER BY invoice_amount DESC;