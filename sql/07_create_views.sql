-- ============================================================
-- Project: Invoice-to-Payment Process Analysis with SQL
-- File: 07_create_views.sql
-- Purpose: Create reusable analytical views for invoice,
--          payment, vendor, and process analysis.
-- SQL Dialect: MySQL
-- ============================================================

USE invoice_to_payment_analysis;


-- ============================================================
-- 1. Drop existing views
-- Makes the script reusable during development.
-- ============================================================

DROP VIEW IF EXISTS vw_invoice_overview;
DROP VIEW IF EXISTS vw_payment_performance;
DROP VIEW IF EXISTS vw_process_step_durations;
DROP VIEW IF EXISTS vw_process_variants;
DROP VIEW IF EXISTS vw_vendor_performance;
DROP VIEW IF EXISTS vw_process_cycle_times;
DROP VIEW IF EXISTS vw_open_process_cases;


-- ============================================================
-- 2. Invoice overview
-- Combines invoice, vendor, department, purchase order,
-- exception, and payment information.
-- ============================================================

CREATE VIEW vw_invoice_overview AS
SELECT
    i.invoice_id,
    i.invoice_number,
    i.invoice_date,
    i.received_date,
    i.invoice_amount,
    i.invoice_status,

    v.vendor_id,
    v.vendor_name,
    v.country AS vendor_country,
    v.vendor_category,
    v.payment_terms_days,
    v.risk_level AS vendor_risk_level,

    d.department_id,
    d.department_name,
    d.cost_center,

    i.po_id,
    po.po_date,
    po.po_amount,
    po.po_status,

    et.exception_type_id,
    et.exception_name,
    et.exception_category,
    et.standard_resolution_days,

    p.payment_id,
    p.scheduled_payment_date,
    p.actual_payment_date,
    p.payment_amount,
    p.payment_status,

    DATEDIFF(i.received_date, i.invoice_date) AS invoice_receipt_delay_days,

    CASE
        WHEN i.exception_type_id IS NULL THEN 'Standard Process'
        ELSE 'Exception Process'
    END AS process_type,

    CASE
        WHEN p.actual_payment_date IS NULL THEN 'Open'
        WHEN p.actual_payment_date < p.scheduled_payment_date THEN 'Paid Early'
        WHEN p.actual_payment_date = p.scheduled_payment_date THEN 'Paid On Time'
        WHEN p.actual_payment_date > p.scheduled_payment_date THEN 'Paid Late'
    END AS payment_timing,

    CASE
        WHEN p.actual_payment_date IS NULL THEN NULL
        ELSE DATEDIFF(p.actual_payment_date, p.scheduled_payment_date)
    END AS payment_delay_days,

    CASE
        WHEN p.payment_status = 'Open' THEN i.invoice_amount
        ELSE 0
    END AS open_invoice_amount,

    CASE
        WHEN po.po_amount IS NULL THEN NULL
        ELSE i.invoice_amount - po.po_amount
    END AS invoice_vs_po_difference

FROM invoices i
INNER JOIN vendors v
    ON i.vendor_id = v.vendor_id
INNER JOIN departments d
    ON i.department_id = d.department_id
LEFT JOIN purchase_orders po
    ON i.po_id = po.po_id
LEFT JOIN exception_types et
    ON i.exception_type_id = et.exception_type_id
LEFT JOIN payments p
    ON i.invoice_id = p.invoice_id;


-- ============================================================
-- 3. Payment performance
-- Focuses on payment timing and open liabilities.
-- ============================================================

CREATE VIEW vw_payment_performance AS
SELECT
    i.invoice_id,
    i.invoice_number,
    i.invoice_amount,
    i.invoice_status,

    v.vendor_id,
    v.vendor_name,
    v.payment_terms_days,
    v.risk_level AS vendor_risk_level,

    p.payment_id,
    p.scheduled_payment_date,
    p.actual_payment_date,
    p.payment_amount,
    p.payment_status,

    CASE
        WHEN p.actual_payment_date IS NULL THEN 'Open'
        WHEN p.actual_payment_date < p.scheduled_payment_date THEN 'Paid Early'
        WHEN p.actual_payment_date = p.scheduled_payment_date THEN 'Paid On Time'
        WHEN p.actual_payment_date > p.scheduled_payment_date THEN 'Paid Late'
    END AS payment_timing,

    CASE
        WHEN p.actual_payment_date IS NULL THEN NULL
        ELSE DATEDIFF(p.actual_payment_date, p.scheduled_payment_date)
    END AS payment_delay_days,

    CASE
        WHEN p.payment_status = 'Open' THEN i.invoice_amount
        ELSE 0
    END AS open_invoice_amount

FROM invoices i
INNER JOIN vendors v
    ON i.vendor_id = v.vendor_id
LEFT JOIN payments p
    ON i.invoice_id = p.invoice_id;


-- ============================================================
-- 4. Process step durations
-- Calculates time between consecutive process events.
-- Uses LAG window function.
-- ============================================================

CREATE VIEW vw_process_step_durations AS
SELECT
    process_steps.invoice_id,
    process_steps.previous_event_name,
    process_steps.event_name,
    process_steps.previous_event_timestamp,
    process_steps.event_timestamp,

    process_steps.department_id,
    d.department_name,

    TIMESTAMPDIFF(
        HOUR,
        process_steps.previous_event_timestamp,
        process_steps.event_timestamp
    ) AS step_duration_hours,

    ROUND(
        TIMESTAMPDIFF(
            HOUR,
            process_steps.previous_event_timestamp,
            process_steps.event_timestamp
        ) / 24,
        2
    ) AS step_duration_days

FROM (
    SELECT
        ie.invoice_id,
        ie.event_name,
        ie.event_timestamp,
        ie.department_id,

        LAG(ie.event_name) OVER (
            PARTITION BY ie.invoice_id
            ORDER BY ie.event_timestamp
        ) AS previous_event_name,

        LAG(ie.event_timestamp) OVER (
            PARTITION BY ie.invoice_id
            ORDER BY ie.event_timestamp
        ) AS previous_event_timestamp

    FROM invoice_events ie
) AS process_steps

INNER JOIN departments d
    ON process_steps.department_id = d.department_id

WHERE process_steps.previous_event_timestamp IS NOT NULL;


-- ============================================================
-- 5. Process variants
-- Reconstructs the event path of each invoice.
-- ============================================================

CREATE VIEW vw_process_variants AS
SELECT
    i.invoice_id,
    i.invoice_number,

    CASE
        WHEN i.exception_type_id IS NULL THEN 'Standard Process'
        ELSE 'Exception Process'
    END AS process_type,

    GROUP_CONCAT(
        ie.event_name
        ORDER BY ie.event_timestamp
        SEPARATOR ' > '
    ) AS process_variant

FROM invoices i
INNER JOIN invoice_events ie
    ON i.invoice_id = ie.invoice_id

GROUP BY
    i.invoice_id,
    i.invoice_number,
    i.exception_type_id;


-- ============================================================
-- 6. Process cycle times
-- Calculates key durations from invoice receipt to payment.
-- ============================================================

CREATE VIEW vw_process_cycle_times AS
SELECT
    i.invoice_id,
    i.invoice_number,
    i.invoice_status,

    v.vendor_id,
    v.vendor_name,

    d.department_id,
    d.department_name,

    CASE
        WHEN i.exception_type_id IS NULL THEN 'Standard Process'
        ELSE 'Exception Process'
    END AS process_type,

    MIN(CASE
        WHEN ie.event_name = 'Invoice Received'
        THEN ie.event_timestamp
    END) AS invoice_received_timestamp,

    MAX(CASE
        WHEN ie.event_name = 'Payment Scheduled'
        THEN ie.event_timestamp
    END) AS payment_scheduled_timestamp,

    MAX(CASE
        WHEN ie.event_name = 'Paid'
        THEN ie.event_timestamp
    END) AS paid_timestamp,

    TIMESTAMPDIFF(
        HOUR,
        MIN(CASE
            WHEN ie.event_name = 'Invoice Received'
            THEN ie.event_timestamp
        END),
        MAX(CASE
            WHEN ie.event_name = 'Payment Scheduled'
            THEN ie.event_timestamp
        END)
    ) AS receipt_to_payment_scheduled_hours,

    TIMESTAMPDIFF(
        HOUR,
        MIN(CASE
            WHEN ie.event_name = 'Invoice Received'
            THEN ie.event_timestamp
        END),
        MAX(CASE
            WHEN ie.event_name = 'Paid'
            THEN ie.event_timestamp
        END)
    ) AS invoice_to_payment_cycle_hours,

    ROUND(
        TIMESTAMPDIFF(
            HOUR,
            MIN(CASE
                WHEN ie.event_name = 'Invoice Received'
                THEN ie.event_timestamp
            END),
            MAX(CASE
                WHEN ie.event_name = 'Paid'
                THEN ie.event_timestamp
            END)
        ) / 24,
        2
    ) AS invoice_to_payment_cycle_days

FROM invoices i
INNER JOIN vendors v
    ON i.vendor_id = v.vendor_id
INNER JOIN departments d
    ON i.department_id = d.department_id
INNER JOIN invoice_events ie
    ON i.invoice_id = ie.invoice_id

GROUP BY
    i.invoice_id,
    i.invoice_number,
    i.invoice_status,
    v.vendor_id,
    v.vendor_name,
    d.department_id,
    d.department_name,
    i.exception_type_id;


-- ============================================================
-- 7. Vendor performance
-- Combines invoice volume, exception rate, payment performance,
-- and average process duration.
-- ============================================================

CREATE VIEW vw_vendor_performance AS
SELECT
    v.vendor_id,
    v.vendor_name,
    v.country,
    v.vendor_category,
    v.payment_terms_days,
    v.risk_level,

    COUNT(DISTINCT i.invoice_id) AS total_invoices,
    COALESCE(SUM(i.invoice_amount), 0) AS total_invoice_amount,
    COALESCE(AVG(i.invoice_amount), 0) AS average_invoice_amount,

    COALESCE(SUM(
        CASE
            WHEN i.exception_type_id IS NOT NULL THEN 1
            ELSE 0
        END
    ), 0) AS exception_invoice_count,

    ROUND(
        COALESCE(
            SUM(
                CASE
                    WHEN i.exception_type_id IS NOT NULL THEN 1
                    ELSE 0
                END
            ) / NULLIF(COUNT(DISTINCT i.invoice_id), 0) * 100,
            0
        ),
        2
    ) AS exception_rate_percent,

    COALESCE(SUM(
        CASE
            WHEN p.payment_status = 'Open' THEN 1
            ELSE 0
        END
    ), 0) AS open_payment_count,

    COALESCE(SUM(
        CASE
            WHEN p.payment_status = 'Open' THEN i.invoice_amount
            ELSE 0
        END
    ), 0) AS open_invoice_amount,

    COALESCE(SUM(
        CASE
            WHEN p.actual_payment_date > p.scheduled_payment_date THEN 1
            ELSE 0
        END
    ), 0) AS late_payment_count,

    ROUND(
        COALESCE(
            SUM(
                CASE
                    WHEN p.actual_payment_date > p.scheduled_payment_date THEN 1
                    ELSE 0
                END
            ) / NULLIF(COUNT(p.payment_id), 0) * 100,
            0
        ),
        2
    ) AS late_payment_rate_percent,

    ROUND(
        AVG(vpct.invoice_to_payment_cycle_hours),
        2
    ) AS avg_invoice_to_payment_cycle_hours,

    ROUND(
        AVG(vpct.invoice_to_payment_cycle_days),
        2
    ) AS avg_invoice_to_payment_cycle_days

FROM vendors v
LEFT JOIN invoices i
    ON v.vendor_id = i.vendor_id
LEFT JOIN payments p
    ON i.invoice_id = p.invoice_id
LEFT JOIN vw_process_cycle_times vpct
    ON i.invoice_id = vpct.invoice_id

GROUP BY
    v.vendor_id,
    v.vendor_name,
    v.country,
    v.vendor_category,
    v.payment_terms_days,
    v.risk_level;


-- ============================================================
-- 8. Open process cases
-- Shows the latest known process event for unfinished invoices.
-- ============================================================

CREATE VIEW vw_open_process_cases AS
SELECT
    i.invoice_id,
    i.invoice_number,
    i.invoice_status,
    i.invoice_amount,

    v.vendor_name,
    d.department_name AS invoice_owner_department,

    latest_event.event_name AS latest_event_name,
    latest_event.event_timestamp AS latest_event_timestamp,
    latest_event.event_status AS latest_event_status,

    event_department.department_name AS latest_event_department,

    CASE
        WHEN i.exception_type_id IS NULL THEN 'Standard Process'
        ELSE 'Exception Process'
    END AS process_type

FROM invoices i
INNER JOIN vendors v
    ON i.vendor_id = v.vendor_id
INNER JOIN departments d
    ON i.department_id = d.department_id

INNER JOIN (
    SELECT
        ranked_events.invoice_id,
        ranked_events.event_name,
        ranked_events.event_timestamp,
        ranked_events.event_status,
        ranked_events.department_id
    FROM (
        SELECT
            ie.invoice_id,
            ie.event_name,
            ie.event_timestamp,
            ie.event_status,
            ie.department_id,

            ROW_NUMBER() OVER (
                PARTITION BY ie.invoice_id
                ORDER BY ie.event_timestamp DESC
            ) AS latest_event_rank

        FROM invoice_events ie
    ) AS ranked_events
    WHERE ranked_events.latest_event_rank = 1
) AS latest_event
    ON i.invoice_id = latest_event.invoice_id

INNER JOIN departments event_department
    ON latest_event.department_id = event_department.department_id

WHERE latest_event.event_name <> 'Paid';