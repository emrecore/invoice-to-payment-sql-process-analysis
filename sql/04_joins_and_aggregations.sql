-- ============================================================
-- Project: Invoice-to-Payment Process Analysis with SQL
-- File: 04_joins_and_aggregations.sql
-- Purpose: Analyze invoice, vendor, department, payment,
--          purchase order, and exception data using joins,
--          aggregations, GROUP BY, HAVING, and aggregate functions.
-- SQL Dialect: MySQL
-- ============================================================

USE invoice_to_payment_analysis;


-- ============================================================
-- 1. Invoice overview with vendor and department
-- Demonstrates INNER JOIN.
-- ============================================================

SELECT
    i.invoice_id,
    i.invoice_number,
    v.vendor_name,
    v.vendor_category,
    d.department_name,
    i.invoice_date,
    i.received_date,
    i.invoice_amount,
    i.invoice_status
FROM invoices i
INNER JOIN vendors v
    ON i.vendor_id = v.vendor_id
INNER JOIN departments d
    ON i.department_id = d.department_id
ORDER BY i.received_date;


-- ============================================================
-- 2. Invoice overview with purchase order information
-- Demonstrates LEFT JOIN because some invoices may not have a PO.
-- ============================================================

SELECT
    i.invoice_id,
    i.invoice_number,
    v.vendor_name,
    i.po_id,
    po.po_amount,
    i.invoice_amount,
    i.invoice_status
FROM invoices i
INNER JOIN vendors v
    ON i.vendor_id = v.vendor_id
LEFT JOIN purchase_orders po
    ON i.po_id = po.po_id
ORDER BY i.invoice_id;


-- ============================================================
-- 3. Invoices with exception details
-- Demonstrates LEFT JOIN with optional exception data.
-- ============================================================

SELECT
    i.invoice_id,
    i.invoice_number,
    v.vendor_name,
    i.invoice_amount,
    i.invoice_status,
    et.exception_name,
    et.exception_category,
    et.standard_resolution_days
FROM invoices i
INNER JOIN vendors v
    ON i.vendor_id = v.vendor_id
LEFT JOIN exception_types et
    ON i.exception_type_id = et.exception_type_id
ORDER BY i.invoice_id;


-- ============================================================
-- 4. Invoices with payment information
-- Demonstrates LEFT JOIN to keep invoices even if payment data is missing.
-- ============================================================

SELECT
    i.invoice_id,
    i.invoice_number,
    v.vendor_name,
    i.invoice_amount,
    i.invoice_status,
    p.scheduled_payment_date,
    p.actual_payment_date,
    p.payment_amount,
    p.payment_status
FROM invoices i
INNER JOIN vendors v
    ON i.vendor_id = v.vendor_id
LEFT JOIN payments p
    ON i.invoice_id = p.invoice_id
ORDER BY i.invoice_id;


-- ============================================================
-- 5. Total invoice amount
-- Demonstrates SUM.
-- ============================================================

SELECT
    SUM(invoice_amount) AS total_invoice_amount
FROM invoices;


-- ============================================================
-- 6. Basic invoice volume and value KPIs
-- Demonstrates COUNT, SUM, AVG, MIN, MAX.
-- ============================================================

SELECT
    COUNT(*) AS total_invoices,
    SUM(invoice_amount) AS total_invoice_amount,
    AVG(invoice_amount) AS average_invoice_amount,
    MIN(invoice_amount) AS smallest_invoice_amount,
    MAX(invoice_amount) AS largest_invoice_amount
FROM invoices;


-- ============================================================
-- 7. Invoice amount by vendor
-- Demonstrates GROUP BY.
-- ============================================================

SELECT
    v.vendor_id,
    v.vendor_name,
    COUNT(i.invoice_id) AS invoice_count,
    SUM(i.invoice_amount) AS total_invoice_amount,
    AVG(i.invoice_amount) AS average_invoice_amount
FROM vendors v
INNER JOIN invoices i
    ON v.vendor_id = i.vendor_id
GROUP BY
    v.vendor_id,
    v.vendor_name
ORDER BY total_invoice_amount DESC;


-- ============================================================
-- 8. Invoice amount by vendor category
-- Business view by supplier segment.
-- ============================================================

SELECT
    v.vendor_category,
    COUNT(i.invoice_id) AS invoice_count,
    SUM(i.invoice_amount) AS total_invoice_amount,
    AVG(i.invoice_amount) AS average_invoice_amount
FROM invoices i
INNER JOIN vendors v
    ON i.vendor_id = v.vendor_id
GROUP BY
    v.vendor_category
ORDER BY total_invoice_amount DESC;


-- ============================================================
-- 9. Invoice amount by department
-- Business view by internal responsibility.
-- ============================================================

SELECT
    d.department_id,
    d.department_name,
    d.cost_center,
    COUNT(i.invoice_id) AS invoice_count,
    SUM(i.invoice_amount) AS total_invoice_amount,
    AVG(i.invoice_amount) AS average_invoice_amount
FROM departments d
INNER JOIN invoices i
    ON d.department_id = i.department_id
GROUP BY
    d.department_id,
    d.department_name,
    d.cost_center
ORDER BY total_invoice_amount DESC;


-- ============================================================
-- 10. Invoice count by invoice status
-- Process status overview.
-- ============================================================

SELECT
    invoice_status,
    COUNT(*) AS invoice_count,
    SUM(invoice_amount) AS total_invoice_amount
FROM invoices
GROUP BY
    invoice_status
ORDER BY invoice_count DESC;


-- ============================================================
-- 11. Payment status overview
-- Payment process overview.
-- ============================================================

SELECT
    payment_status,
    COUNT(*) AS payment_count,
    SUM(payment_amount) AS total_payment_amount
FROM payments
GROUP BY
    payment_status
ORDER BY payment_count DESC;


-- ============================================================
-- 12. Payment timing classification overview
-- Demonstrates aggregation on CASE WHEN.
-- ============================================================

SELECT
    CASE
        WHEN actual_payment_date IS NULL THEN 'Open'
        WHEN actual_payment_date < scheduled_payment_date THEN 'Paid Early'
        WHEN actual_payment_date = scheduled_payment_date THEN 'Paid On Time'
        WHEN actual_payment_date > scheduled_payment_date THEN 'Paid Late'
    END AS payment_timing,
    COUNT(*) AS payment_count,
    SUM(payment_amount) AS total_payment_amount
FROM payments
GROUP BY
    CASE
        WHEN actual_payment_date IS NULL THEN 'Open'
        WHEN actual_payment_date < scheduled_payment_date THEN 'Paid Early'
        WHEN actual_payment_date = scheduled_payment_date THEN 'Paid On Time'
        WHEN actual_payment_date > scheduled_payment_date THEN 'Paid Late'
    END
ORDER BY payment_count DESC;


-- ============================================================
-- 13. Late payment analysis by vendor
-- Measures delayed payments per vendor.
-- ============================================================

SELECT
    v.vendor_id,
    v.vendor_name,
    COUNT(p.payment_id) AS total_payments,
    SUM(
        CASE
            WHEN p.actual_payment_date > p.scheduled_payment_date THEN 1
            ELSE 0
        END
    ) AS late_payments,
    ROUND(
        SUM(
            CASE
                WHEN p.actual_payment_date > p.scheduled_payment_date THEN 1
                ELSE 0
            END
        ) / COUNT(p.payment_id) * 100,
        2
    ) AS late_payment_rate_percent,
    AVG(
        CASE
            WHEN p.actual_payment_date > p.scheduled_payment_date
            THEN DATEDIFF(p.actual_payment_date, p.scheduled_payment_date)
            ELSE NULL
        END
    ) AS avg_late_payment_delay_days
FROM vendors v
INNER JOIN invoices i
    ON v.vendor_id = i.vendor_id
INNER JOIN payments p
    ON i.invoice_id = p.invoice_id
GROUP BY
    v.vendor_id,
    v.vendor_name
ORDER BY late_payment_rate_percent DESC, avg_late_payment_delay_days DESC;


-- ============================================================
-- 14. Open invoice amount by vendor
-- Measures unpaid invoice value.
-- ============================================================

SELECT
    v.vendor_id,
    v.vendor_name,
    COUNT(i.invoice_id) AS open_invoice_count,
    SUM(i.invoice_amount) AS open_invoice_amount
FROM vendors v
INNER JOIN invoices i
    ON v.vendor_id = i.vendor_id
INNER JOIN payments p
    ON i.invoice_id = p.invoice_id
WHERE p.payment_status = 'Open'
GROUP BY
    v.vendor_id,
    v.vendor_name
ORDER BY open_invoice_amount DESC;


-- ============================================================
-- 15. Exception count by exception type
-- Identifies most frequent invoice issues.
-- ============================================================

SELECT
    et.exception_type_id,
    et.exception_name,
    et.exception_category,
    COUNT(i.invoice_id) AS exception_count,
    SUM(i.invoice_amount) AS affected_invoice_amount
FROM exception_types et
INNER JOIN invoices i
    ON et.exception_type_id = i.exception_type_id
GROUP BY
    et.exception_type_id,
    et.exception_name,
    et.exception_category
ORDER BY exception_count DESC, affected_invoice_amount DESC;


-- ============================================================
-- 16. Exception analysis by vendor
-- Identifies vendors associated with exception cases.
-- ============================================================

SELECT
    v.vendor_id,
    v.vendor_name,
    COUNT(i.invoice_id) AS total_invoices,
    SUM(
        CASE
            WHEN i.exception_type_id IS NOT NULL THEN 1
            ELSE 0
        END
    ) AS exception_invoices,
    ROUND(
        SUM(
            CASE
                WHEN i.exception_type_id IS NOT NULL THEN 1
                ELSE 0
            END
        ) / COUNT(i.invoice_id) * 100,
        2
    ) AS exception_rate_percent
FROM vendors v
INNER JOIN invoices i
    ON v.vendor_id = i.vendor_id
GROUP BY
    v.vendor_id,
    v.vendor_name
ORDER BY exception_rate_percent DESC, exception_invoices DESC;


-- ============================================================
-- 17. Exception analysis by department
-- Identifies departments with frequent invoice exceptions.
-- ============================================================

SELECT
    d.department_id,
    d.department_name,
    COUNT(i.invoice_id) AS total_invoices,
    SUM(
        CASE
            WHEN i.exception_type_id IS NOT NULL THEN 1
            ELSE 0
        END
    ) AS exception_invoices,
    ROUND(
        SUM(
            CASE
                WHEN i.exception_type_id IS NOT NULL THEN 1
                ELSE 0
            END
        ) / COUNT(i.invoice_id) * 100,
        2
    ) AS exception_rate_percent
FROM departments d
INNER JOIN invoices i
    ON d.department_id = i.department_id
GROUP BY
    d.department_id,
    d.department_name
ORDER BY exception_rate_percent DESC, exception_invoices DESC;


-- ============================================================
-- 18. Compare invoice amount with purchase order amount
-- Identifies possible price mismatches or partial invoices.
-- ============================================================

SELECT
    i.invoice_id,
    i.invoice_number,
    v.vendor_name,
    i.po_id,
    po.po_amount,
    i.invoice_amount,
    i.invoice_amount - po.po_amount AS amount_difference
FROM invoices i
INNER JOIN vendors v
    ON i.vendor_id = v.vendor_id
LEFT JOIN purchase_orders po
    ON i.po_id = po.po_id
ORDER BY ABS(i.invoice_amount - po.po_amount) DESC;


-- ============================================================
-- 19. Purchase order utilization by invoice amount
-- Aggregates invoices against purchase order value.
-- ============================================================

SELECT
    po.po_id,
    v.vendor_name,
    po.po_amount,
    COUNT(i.invoice_id) AS invoice_count,
    SUM(i.invoice_amount) AS total_invoiced_amount,
    SUM(i.invoice_amount) - po.po_amount AS invoice_vs_po_difference
FROM purchase_orders po
INNER JOIN vendors v
    ON po.vendor_id = v.vendor_id
LEFT JOIN invoices i
    ON po.po_id = i.po_id
GROUP BY
    po.po_id,
    v.vendor_name,
    po.po_amount
ORDER BY ABS(invoice_vs_po_difference) DESC;


-- ============================================================
-- 20. Vendors with more than one invoice
-- Demonstrates HAVING.
-- ============================================================

SELECT
    v.vendor_id,
    v.vendor_name,
    COUNT(i.invoice_id) AS invoice_count
FROM vendors v
INNER JOIN invoices i
    ON v.vendor_id = i.vendor_id
GROUP BY
    v.vendor_id,
    v.vendor_name
HAVING COUNT(i.invoice_id) > 1
ORDER BY invoice_count DESC;


-- ============================================================
-- 21. Departments with total invoice amount above 10,000 EUR
-- Demonstrates HAVING with SUM.
-- ============================================================

SELECT
    d.department_id,
    d.department_name,
    SUM(i.invoice_amount) AS total_invoice_amount
FROM departments d
INNER JOIN invoices i
    ON d.department_id = i.department_id
GROUP BY
    d.department_id,
    d.department_name
HAVING SUM(i.invoice_amount) > 10000
ORDER BY total_invoice_amount DESC;


-- ============================================================
-- 22. Vendors with exception rate above 50 percent
-- Demonstrates HAVING with calculated logic.
-- ============================================================

SELECT
    v.vendor_id,
    v.vendor_name,
    COUNT(i.invoice_id) AS total_invoices,
    SUM(
        CASE
            WHEN i.exception_type_id IS NOT NULL THEN 1
            ELSE 0
        END
    ) AS exception_invoices,
    ROUND(
        SUM(
            CASE
                WHEN i.exception_type_id IS NOT NULL THEN 1
                ELSE 0
            END
        ) / COUNT(i.invoice_id) * 100,
        2
    ) AS exception_rate_percent
FROM vendors v
INNER JOIN invoices i
    ON v.vendor_id = i.vendor_id
GROUP BY
    v.vendor_id,
    v.vendor_name
HAVING exception_rate_percent > 50
ORDER BY exception_rate_percent DESC;


-- ============================================================
-- 23. Average invoice receipt delay by vendor
-- Measures time between invoice date and received date.
-- ============================================================

SELECT
    v.vendor_id,
    v.vendor_name,
    AVG(DATEDIFF(i.received_date, i.invoice_date)) AS avg_days_until_received,
    MAX(DATEDIFF(i.received_date, i.invoice_date)) AS max_days_until_received
FROM vendors v
INNER JOIN invoices i
    ON v.vendor_id = i.vendor_id
GROUP BY
    v.vendor_id,
    v.vendor_name
ORDER BY avg_days_until_received DESC;


-- ============================================================
-- 24. Invoice processing event count by invoice
-- Counts how many events each invoice passed through.
-- ============================================================

SELECT
    i.invoice_id,
    i.invoice_number,
    v.vendor_name,
    COUNT(ie.event_id) AS process_event_count
FROM invoices i
INNER JOIN vendors v
    ON i.vendor_id = v.vendor_id
LEFT JOIN invoice_events ie
    ON i.invoice_id = ie.invoice_id
GROUP BY
    i.invoice_id,
    i.invoice_number,
    v.vendor_name
ORDER BY process_event_count DESC;


-- ============================================================
-- 25. Event count by event name
-- Shows how often each process step occurred.
-- ============================================================

SELECT
    event_name,
    COUNT(*) AS event_count
FROM invoice_events
GROUP BY
    event_name
ORDER BY event_count DESC;


-- ============================================================
-- 26. Event count by department
-- Shows process workload by department.
-- ============================================================

SELECT
    d.department_id,
    d.department_name,
    COUNT(ie.event_id) AS event_count
FROM departments d
INNER JOIN invoice_events ie
    ON d.department_id = ie.department_id
GROUP BY
    d.department_id,
    d.department_name
ORDER BY event_count DESC;


-- ============================================================
-- 27. Pending events by department
-- Identifies where work is currently waiting.
-- ============================================================

SELECT
    d.department_id,
    d.department_name,
    COUNT(ie.event_id) AS pending_event_count
FROM departments d
INNER JOIN invoice_events ie
    ON d.department_id = ie.department_id
WHERE ie.event_status = 'Pending'
GROUP BY
    d.department_id,
    d.department_name
ORDER BY pending_event_count DESC;


-- ============================================================
-- 28. Open payment exposure by department
-- Shows unpaid invoice value by responsible department.
-- ============================================================

SELECT
    d.department_id,
    d.department_name,
    COUNT(i.invoice_id) AS open_invoice_count,
    SUM(i.invoice_amount) AS open_invoice_amount
FROM departments d
INNER JOIN invoices i
    ON d.department_id = i.department_id
INNER JOIN payments p
    ON i.invoice_id = p.invoice_id
WHERE p.payment_status = 'Open'
GROUP BY
    d.department_id,
    d.department_name
ORDER BY open_invoice_amount DESC;


-- ============================================================
-- 29. Vendor performance summary
-- Combines invoice volume, exceptions, and open payments.
-- ============================================================

SELECT
    v.vendor_id,
    v.vendor_name,
    v.risk_level,
    COUNT(DISTINCT i.invoice_id) AS total_invoices,
    SUM(i.invoice_amount) AS total_invoice_amount,
    SUM(
        CASE
            WHEN i.exception_type_id IS NOT NULL THEN 1
            ELSE 0
        END
    ) AS exception_invoice_count,
    SUM(
        CASE
            WHEN p.payment_status = 'Open' THEN 1
            ELSE 0
        END
    ) AS open_payment_count,
    SUM(
        CASE
            WHEN p.payment_status = 'Open' THEN i.invoice_amount
            ELSE 0
        END
    ) AS open_invoice_amount
FROM vendors v
LEFT JOIN invoices i
    ON v.vendor_id = i.vendor_id
LEFT JOIN payments p
    ON i.invoice_id = p.invoice_id
GROUP BY
    v.vendor_id,
    v.vendor_name,
    v.risk_level
ORDER BY open_invoice_amount DESC, exception_invoice_count DESC;


-- ============================================================
-- 30. Executive invoice and payment summary
-- Compact management-level KPI overview.
-- ============================================================

SELECT
    COUNT(DISTINCT i.invoice_id) AS total_invoices,
    SUM(i.invoice_amount) AS total_invoice_amount,
    SUM(
        CASE
            WHEN i.exception_type_id IS NOT NULL THEN 1
            ELSE 0
        END
    ) AS exception_invoice_count,
    ROUND(
        SUM(
            CASE
                WHEN i.exception_type_id IS NOT NULL THEN 1
                ELSE 0
            END
        ) / COUNT(DISTINCT i.invoice_id) * 100,
        2
    ) AS exception_rate_percent,
    SUM(
        CASE
            WHEN p.payment_status = 'Open' THEN 1
            ELSE 0
        END
    ) AS open_payment_count,
    SUM(
        CASE
            WHEN p.payment_status = 'Open' THEN i.invoice_amount
            ELSE 0
        END
    ) AS open_invoice_amount,
    SUM(
        CASE
            WHEN p.actual_payment_date > p.scheduled_payment_date THEN 1
            ELSE 0
        END
    ) AS late_payment_count
FROM invoices i
LEFT JOIN payments p
    ON i.invoice_id = p.invoice_id;