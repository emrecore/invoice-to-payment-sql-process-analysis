-- ============================================================
-- Project: Invoice-to-Payment Process Analysis with SQL
-- File: 06_data_quality_checks.sql
-- Purpose: Identify missing, inconsistent, duplicate, or
--          suspicious records in the Invoice-to-Payment dataset.
-- SQL Dialect: MySQL
-- ============================================================

USE invoice_to_payment_analysis;


-- ============================================================
-- 1. Invoices without payment records
-- Checks whether every invoice has a related payment entry.
-- ============================================================

SELECT
    i.invoice_id,
    i.invoice_number,
    i.invoice_amount,
    i.invoice_status
FROM invoices i
LEFT JOIN payments p
    ON i.invoice_id = p.invoice_id
WHERE p.payment_id IS NULL
ORDER BY i.invoice_id;


-- ============================================================
-- 2. Paid invoices without an actual payment date
-- A payment marked as Paid should have a payment date.
-- ============================================================

SELECT
    p.payment_id,
    p.invoice_id,
    p.payment_status,
    p.scheduled_payment_date,
    p.actual_payment_date,
    p.payment_amount
FROM payments p
WHERE p.payment_status = 'Paid'
  AND p.actual_payment_date IS NULL
ORDER BY p.invoice_id;


-- ============================================================
-- 3. Open payments with an actual payment date
-- Open payment records should not already contain a payment date.
-- ============================================================

SELECT
    p.payment_id,
    p.invoice_id,
    p.payment_status,
    p.scheduled_payment_date,
    p.actual_payment_date,
    p.payment_amount
FROM payments p
WHERE p.payment_status = 'Open'
  AND p.actual_payment_date IS NOT NULL
ORDER BY p.invoice_id;


-- ============================================================
-- 4. Paid payments with zero payment amount
-- A paid invoice should normally have a positive payment amount.
-- ============================================================

SELECT
    p.payment_id,
    p.invoice_id,
    p.payment_status,
    p.payment_amount
FROM payments p
WHERE p.payment_status = 'Paid'
  AND p.payment_amount <= 0
ORDER BY p.invoice_id;


-- ============================================================
-- 5. Open payments with a positive payment amount
-- In this simplified model, open payments should have amount 0.
-- ============================================================

SELECT
    p.payment_id,
    p.invoice_id,
    p.payment_status,
    p.payment_amount
FROM payments p
WHERE p.payment_status = 'Open'
  AND p.payment_amount > 0
ORDER BY p.invoice_id;


-- ============================================================
-- 6. Invoice status inconsistent with payment status
-- Paid invoices should generally have a paid payment record.
-- ============================================================

SELECT
    i.invoice_id,
    i.invoice_number,
    i.invoice_status,
    p.payment_status,
    p.actual_payment_date,
    p.payment_amount
FROM invoices i
INNER JOIN payments p
    ON i.invoice_id = p.invoice_id
WHERE
    (i.invoice_status = 'Paid' AND p.payment_status <> 'Paid')
    OR
    (i.invoice_status <> 'Paid' AND p.payment_status = 'Paid')
ORDER BY i.invoice_id;


-- ============================================================
-- 7. Payments made before invoice receipt
-- Payment should not happen before the invoice was received.
-- ============================================================

SELECT
    i.invoice_id,
    i.invoice_number,
    i.received_date,
    p.actual_payment_date,
    p.payment_amount
FROM invoices i
INNER JOIN payments p
    ON i.invoice_id = p.invoice_id
WHERE p.actual_payment_date < i.received_date
ORDER BY i.invoice_id;


-- ============================================================
-- 8. Payment scheduled before invoice receipt
-- Scheduled payment should not be before receipt of invoice.
-- ============================================================

SELECT
    i.invoice_id,
    i.invoice_number,
    i.received_date,
    p.scheduled_payment_date
FROM invoices i
INNER JOIN payments p
    ON i.invoice_id = p.invoice_id
WHERE p.scheduled_payment_date < i.received_date
ORDER BY i.invoice_id;


-- ============================================================
-- 9. Invoice received before invoice date
-- This should not happen based on the business logic.
-- ============================================================

SELECT
    invoice_id,
    invoice_number,
    invoice_date,
    received_date
FROM invoices
WHERE received_date < invoice_date
ORDER BY invoice_id;


-- ============================================================
-- 10. Invoices without purchase order reference
-- These are not always invalid, but they require review.
-- ============================================================

SELECT
    i.invoice_id,
    i.invoice_number,
    v.vendor_name,
    i.invoice_amount,
    i.invoice_status,
    i.exception_type_id
FROM invoices i
INNER JOIN vendors v
    ON i.vendor_id = v.vendor_id
WHERE i.po_id IS NULL
ORDER BY i.invoice_id;


-- ============================================================
-- 11. Invoices with missing PO but no Missing Purchase Order exception
-- More specific consistency check.
-- ============================================================

SELECT
    i.invoice_id,
    i.invoice_number,
    v.vendor_name,
    i.invoice_amount,
    i.exception_type_id
FROM invoices i
INNER JOIN vendors v
    ON i.vendor_id = v.vendor_id
LEFT JOIN exception_types et
    ON i.exception_type_id = et.exception_type_id
WHERE i.po_id IS NULL
  AND (
      et.exception_name IS NULL
      OR et.exception_name <> 'Missing Purchase Order'
  )
ORDER BY i.invoice_id;


-- ============================================================
-- 12. Invoice vendor differs from PO vendor
-- Invoice and linked PO should belong to the same vendor.
-- ============================================================

SELECT
    i.invoice_id,
    i.invoice_number,
    i.vendor_id AS invoice_vendor_id,
    po.vendor_id AS po_vendor_id,
    i.po_id
FROM invoices i
INNER JOIN purchase_orders po
    ON i.po_id = po.po_id
WHERE i.vendor_id <> po.vendor_id
ORDER BY i.invoice_id;


-- ============================================================
-- 13. Invoice department differs from PO department
-- Requires review because invoice ownership may be inconsistent.
-- ============================================================

SELECT
    i.invoice_id,
    i.invoice_number,
    i.department_id AS invoice_department_id,
    po.department_id AS po_department_id,
    i.po_id
FROM invoices i
INNER JOIN purchase_orders po
    ON i.po_id = po.po_id
WHERE i.department_id <> po.department_id
ORDER BY i.invoice_id;


-- ============================================================
-- 14. Invoice amount significantly exceeds PO amount
-- Threshold used: invoice is more than 10 percent above PO value.
-- ============================================================

SELECT
    i.invoice_id,
    i.invoice_number,
    v.vendor_name,
    i.po_id,
    po.po_amount,
    i.invoice_amount,
    ROUND(
        ((i.invoice_amount - po.po_amount) / po.po_amount) * 100,
        2
    ) AS variance_percent
FROM invoices i
INNER JOIN purchase_orders po
    ON i.po_id = po.po_id
INNER JOIN vendors v
    ON i.vendor_id = v.vendor_id
WHERE i.invoice_amount > po.po_amount * 1.10
ORDER BY variance_percent DESC;


-- ============================================================
-- 15. Invoice amount significantly below PO amount
-- Threshold used: invoice is more than 10 percent below PO value.
-- ============================================================

SELECT
    i.invoice_id,
    i.invoice_number,
    v.vendor_name,
    i.po_id,
    po.po_amount,
    i.invoice_amount,
    ROUND(
        ((i.invoice_amount - po.po_amount) / po.po_amount) * 100,
        2
    ) AS variance_percent
FROM invoices i
INNER JOIN purchase_orders po
    ON i.po_id = po.po_id
INNER JOIN vendors v
    ON i.vendor_id = v.vendor_id
WHERE i.invoice_amount < po.po_amount * 0.90
ORDER BY variance_percent ASC;


-- ============================================================
-- 16. Duplicate invoice numbers
-- Invoice numbers should be unique.
-- ============================================================

SELECT
    invoice_number,
    COUNT(*) AS duplicate_count
FROM invoices
GROUP BY invoice_number
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;


-- ============================================================
-- 17. Potential duplicate invoices
-- Same vendor, same amount, same invoice date.
-- ============================================================

SELECT
    v.vendor_name,
    i.invoice_date,
    i.invoice_amount,
    COUNT(*) AS possible_duplicate_count,
    GROUP_CONCAT(i.invoice_number ORDER BY i.invoice_number SEPARATOR ', ') AS invoice_numbers
FROM invoices i
INNER JOIN vendors v
    ON i.vendor_id = v.vendor_id
GROUP BY
    v.vendor_name,
    i.invoice_date,
    i.invoice_amount
HAVING COUNT(*) > 1
ORDER BY possible_duplicate_count DESC;


-- ============================================================
-- 18. Invoices without process events
-- Every invoice should have at least one event.
-- ============================================================

SELECT
    i.invoice_id,
    i.invoice_number,
    i.invoice_status,
    i.received_date
FROM invoices i
LEFT JOIN invoice_events ie
    ON i.invoice_id = ie.invoice_id
WHERE ie.event_id IS NULL
ORDER BY i.invoice_id;


-- ============================================================
-- 19. Process events without invoice received event
-- Every process should normally begin with Invoice Received.
-- ============================================================

SELECT
    i.invoice_id,
    i.invoice_number
FROM invoices i
WHERE NOT EXISTS (
    SELECT 1
    FROM invoice_events ie
    WHERE ie.invoice_id = i.invoice_id
      AND ie.event_name = 'Invoice Received'
)
ORDER BY i.invoice_id;


-- ============================================================
-- 20. Paid invoices without Paid event
-- A paid invoice should include a Paid event in the process log.
-- ============================================================

SELECT
    i.invoice_id,
    i.invoice_number,
    i.invoice_status
FROM invoices i
WHERE i.invoice_status = 'Paid'
  AND NOT EXISTS (
      SELECT 1
      FROM invoice_events ie
      WHERE ie.invoice_id = i.invoice_id
        AND ie.event_name = 'Paid'
  )
ORDER BY i.invoice_id;


-- ============================================================
-- 21. Open invoices with Paid event
-- An invoice not marked Paid should not have a completed Paid event.
-- ============================================================

SELECT
    i.invoice_id,
    i.invoice_number,
    i.invoice_status,
    ie.event_timestamp AS paid_event_timestamp
FROM invoices i
INNER JOIN invoice_events ie
    ON i.invoice_id = ie.invoice_id
WHERE i.invoice_status <> 'Paid'
  AND ie.event_name = 'Paid'
ORDER BY i.invoice_id;


-- ============================================================
-- 22. Paid event earlier than Invoice Received event
-- Checks event sequence logic.
-- ============================================================

WITH invoice_event_dates AS (
    SELECT
        invoice_id,
        MIN(CASE WHEN event_name = 'Invoice Received' THEN event_timestamp END) AS invoice_received_timestamp,
        MIN(CASE WHEN event_name = 'Paid' THEN event_timestamp END) AS paid_timestamp
    FROM invoice_events
    GROUP BY invoice_id
)

SELECT
    i.invoice_id,
    i.invoice_number,
    ied.invoice_received_timestamp,
    ied.paid_timestamp
FROM invoice_event_dates ied
INNER JOIN invoices i
    ON ied.invoice_id = i.invoice_id
WHERE ied.paid_timestamp IS NOT NULL
  AND ied.invoice_received_timestamp IS NOT NULL
  AND ied.paid_timestamp < ied.invoice_received_timestamp
ORDER BY i.invoice_id;


-- ============================================================
-- 23. Payment Scheduled event earlier than Invoice Received
-- Checks process event order.
-- ============================================================

WITH invoice_event_dates AS (
    SELECT
        invoice_id,
        MIN(CASE WHEN event_name = 'Invoice Received' THEN event_timestamp END) AS invoice_received_timestamp,
        MIN(CASE WHEN event_name = 'Payment Scheduled' THEN event_timestamp END) AS payment_scheduled_timestamp
    FROM invoice_events
    GROUP BY invoice_id
)

SELECT
    i.invoice_id,
    i.invoice_number,
    ied.invoice_received_timestamp,
    ied.payment_scheduled_timestamp
FROM invoice_event_dates ied
INNER JOIN invoices i
    ON ied.invoice_id = i.invoice_id
WHERE ied.payment_scheduled_timestamp IS NOT NULL
  AND ied.invoice_received_timestamp IS NOT NULL
  AND ied.payment_scheduled_timestamp < ied.invoice_received_timestamp
ORDER BY i.invoice_id;


-- ============================================================
-- 24. Events occurring after a Paid event
-- Normally, no process event should happen after payment.
-- ============================================================

WITH paid_events AS (
    SELECT
        invoice_id,
        MIN(event_timestamp) AS paid_timestamp
    FROM invoice_events
    WHERE event_name = 'Paid'
    GROUP BY invoice_id
)

SELECT
    ie.invoice_id,
    ie.event_id,
    ie.event_name,
    ie.event_timestamp,
    pe.paid_timestamp
FROM invoice_events ie
INNER JOIN paid_events pe
    ON ie.invoice_id = pe.invoice_id
WHERE ie.event_timestamp > pe.paid_timestamp
ORDER BY
    ie.invoice_id,
    ie.event_timestamp;


-- ============================================================
-- 25. Duplicate event names per invoice
-- Some events may legitimately repeat, but duplicates should be reviewed.
-- ============================================================

SELECT
    invoice_id,
    event_name,
    COUNT(*) AS duplicate_event_count
FROM invoice_events
GROUP BY
    invoice_id,
    event_name
HAVING COUNT(*) > 1
ORDER BY
    duplicate_event_count DESC,
    invoice_id;


-- ============================================================
-- 26. Invalid pending event after a paid invoice
-- Paid invoices should not still contain pending events.
-- ============================================================

SELECT
    i.invoice_id,
    i.invoice_number,
    i.invoice_status,
    ie.event_name,
    ie.event_timestamp,
    ie.event_status
FROM invoices i
INNER JOIN invoice_events ie
    ON i.invoice_id = ie.invoice_id
WHERE i.invoice_status = 'Paid'
  AND ie.event_status = 'Pending'
ORDER BY
    i.invoice_id,
    ie.event_timestamp;


-- ============================================================
-- 27. Invoices with exception type but no exception event
-- Exception metadata should be reflected in the event log.
-- ============================================================

SELECT
    i.invoice_id,
    i.invoice_number,
    et.exception_name
FROM invoices i
INNER JOIN exception_types et
    ON i.exception_type_id = et.exception_type_id
WHERE NOT EXISTS (
    SELECT 1
    FROM invoice_events ie
    WHERE ie.invoice_id = i.invoice_id
      AND ie.event_name = 'Exception Raised'
)
ORDER BY i.invoice_id;


-- ============================================================
-- 28. Exception event but no exception type in invoice record
-- Reverse consistency check.
-- ============================================================

SELECT DISTINCT
    i.invoice_id,
    i.invoice_number,
    i.exception_type_id
FROM invoices i
INNER JOIN invoice_events ie
    ON i.invoice_id = ie.invoice_id
WHERE ie.event_name = 'Exception Raised'
  AND i.exception_type_id IS NULL
ORDER BY i.invoice_id;


-- ============================================================
-- 29. Events with a department different from invoice department
-- Not always invalid, but useful for responsibility review.
-- ============================================================

SELECT
    i.invoice_id,
    i.invoice_number,
    d_invoice.department_name AS invoice_department,
    d_event.department_name AS event_department,
    ie.event_name,
    ie.event_timestamp
FROM invoices i
INNER JOIN invoice_events ie
    ON i.invoice_id = ie.invoice_id
INNER JOIN departments d_invoice
    ON i.department_id = d_invoice.department_id
INNER JOIN departments d_event
    ON ie.department_id = d_event.department_id
WHERE i.department_id <> ie.department_id
ORDER BY
    i.invoice_id,
    ie.event_timestamp;


-- ============================================================
-- 30. Process event gaps greater than 7 days
-- Highlights unusually long waiting periods between steps.
-- ============================================================

WITH ordered_events AS (
    SELECT
        invoice_id,
        event_name,
        event_timestamp,
        LAG(event_name) OVER (
            PARTITION BY invoice_id
            ORDER BY event_timestamp
        ) AS previous_event_name,
        LAG(event_timestamp) OVER (
            PARTITION BY invoice_id
            ORDER BY event_timestamp
        ) AS previous_event_timestamp
    FROM invoice_events
)

SELECT
    invoice_id,
    previous_event_name,
    event_name,
    previous_event_timestamp,
    event_timestamp,
    TIMESTAMPDIFF(DAY, previous_event_timestamp, event_timestamp) AS gap_days
FROM ordered_events
WHERE previous_event_timestamp IS NOT NULL
  AND TIMESTAMPDIFF(DAY, previous_event_timestamp, event_timestamp) > 7
ORDER BY gap_days DESC;


-- ============================================================
-- 31. Invoice status versus latest process event
-- Checks whether invoice status matches final event in the log.
-- ============================================================

WITH latest_event AS (
    SELECT
        invoice_id,
        event_name,
        event_status,
        event_timestamp,
        ROW_NUMBER() OVER (
            PARTITION BY invoice_id
            ORDER BY event_timestamp DESC
        ) AS latest_event_rank
    FROM invoice_events
)

SELECT
    i.invoice_id,
    i.invoice_number,
    i.invoice_status,
    le.event_name AS latest_event_name,
    le.event_status AS latest_event_status,
    le.event_timestamp AS latest_event_timestamp
FROM invoices i
INNER JOIN latest_event le
    ON i.invoice_id = le.invoice_id
WHERE le.latest_event_rank = 1
  AND (
      (i.invoice_status = 'Paid' AND le.event_name <> 'Paid')
      OR
      (i.invoice_status IN ('Approved', 'In Review', 'Received') AND le.event_name = 'Paid')
  )
ORDER BY i.invoice_id;


-- ============================================================
-- 32. Purchase orders without invoices
-- Not necessarily wrong, but indicates unused or pending POs.
-- ============================================================

SELECT
    po.po_id,
    po.po_date,
    po.po_amount,
    po.po_status,
    v.vendor_name,
    d.department_name
FROM purchase_orders po
INNER JOIN vendors v
    ON po.vendor_id = v.vendor_id
INNER JOIN departments d
    ON po.department_id = d.department_id
LEFT JOIN invoices i
    ON po.po_id = i.po_id
WHERE i.invoice_id IS NULL
ORDER BY po.po_date;


-- ============================================================
-- 33. Invoice count exceeding expected PO relationship
-- Shows POs linked to multiple invoices for review.
-- ============================================================

SELECT
    po.po_id,
    v.vendor_name,
    po.po_amount,
    COUNT(i.invoice_id) AS linked_invoice_count,
    SUM(i.invoice_amount) AS total_linked_invoice_amount
FROM purchase_orders po
INNER JOIN vendors v
    ON po.vendor_id = v.vendor_id
LEFT JOIN invoices i
    ON po.po_id = i.po_id
GROUP BY
    po.po_id,
    v.vendor_name,
    po.po_amount
HAVING COUNT(i.invoice_id) > 1
ORDER BY linked_invoice_count DESC;


-- ============================================================
-- 34. Payment amount differs from invoice amount
-- In this simplified model, paid payment amount should match invoice amount.
-- ============================================================

SELECT
    i.invoice_id,
    i.invoice_number,
    i.invoice_amount,
    p.payment_amount,
    i.invoice_amount - p.payment_amount AS amount_difference,
    p.payment_status
FROM invoices i
INNER JOIN payments p
    ON i.invoice_id = p.invoice_id
WHERE p.payment_status = 'Paid'
  AND i.invoice_amount <> p.payment_amount
ORDER BY ABS(amount_difference) DESC;


-- ============================================================
-- 35. Summary of data quality control results
-- Gives a compact count-based overview.
-- ============================================================

SELECT
    (
        SELECT COUNT(*)
        FROM invoices i
        LEFT JOIN payments p
            ON i.invoice_id = p.invoice_id
        WHERE p.payment_id IS NULL
    ) AS invoices_without_payment_record,

    (
        SELECT COUNT(*)
        FROM payments
        WHERE payment_status = 'Paid'
          AND actual_payment_date IS NULL
    ) AS paid_payments_without_actual_date,

    (
        SELECT COUNT(*)
        FROM invoices
        WHERE po_id IS NULL
    ) AS invoices_without_purchase_order,

    (
        SELECT COUNT(*)
        FROM invoices i
        LEFT JOIN invoice_events ie
            ON i.invoice_id = ie.invoice_id
        WHERE ie.event_id IS NULL
    ) AS invoices_without_events,

    (
        SELECT COUNT(*)
        FROM invoices i
        INNER JOIN payments p
            ON i.invoice_id = p.invoice_id
        WHERE i.invoice_status = 'Paid'
          AND p.payment_status <> 'Paid'
    ) AS invoice_payment_status_mismatches,

    (
        SELECT COUNT(*)
        FROM invoices i
        INNER JOIN purchase_orders po
            ON i.po_id = po.po_id
        WHERE i.vendor_id <> po.vendor_id
    ) AS invoice_po_vendor_mismatches;