-- ============================================================
-- Project: Invoice-to-Payment Process Analysis with SQL
-- File: 05_process_analysis.sql
-- Purpose: Analyze invoice process flows, process durations,
--          bottlenecks, event sequences, and exception impact.
-- SQL Dialect: MySQL 8.0+
-- ============================================================

USE invoice_to_payment_analysis;


-- ============================================================
-- 1. Chronological event log
-- Shows all process events in correct order.
-- ============================================================

SELECT
    ie.invoice_id,
    i.invoice_number,
    ie.event_name,
    ie.event_timestamp,
    d.department_name,
    ie.event_status
FROM invoice_events ie
INNER JOIN invoices i
    ON ie.invoice_id = i.invoice_id
INNER JOIN departments d
    ON ie.department_id = d.department_id
ORDER BY
    ie.invoice_id,
    ie.event_timestamp;


-- ============================================================
-- 2. Number events per invoice chronologically
-- Demonstrates ROW_NUMBER window function.
-- ============================================================

SELECT
    invoice_id,
    event_name,
    event_timestamp,
    ROW_NUMBER() OVER (
        PARTITION BY invoice_id
        ORDER BY event_timestamp
    ) AS event_sequence_number
FROM invoice_events
ORDER BY
    invoice_id,
    event_sequence_number;


-- ============================================================
-- 3. Identify previous event for each invoice event
-- Demonstrates LAG window function.
-- ============================================================

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
ORDER BY
    invoice_id,
    event_timestamp;


-- ============================================================
-- 4. Calculate duration between consecutive process events
-- Measures step duration in hours.
-- ============================================================

SELECT
    invoice_id,
    previous_event_name,
    event_name,
    previous_event_timestamp,
    event_timestamp,
    TIMESTAMPDIFF(HOUR, previous_event_timestamp, event_timestamp) AS step_duration_hours
FROM (
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
) event_steps
WHERE previous_event_timestamp IS NOT NULL
ORDER BY
    invoice_id,
    event_timestamp;


-- ============================================================
-- 5. Process step duration with department information
-- Adds responsible department for the current event.
-- ============================================================

SELECT
    event_steps.invoice_id,
    event_steps.previous_event_name,
    event_steps.event_name,
    event_steps.previous_event_timestamp,
    event_steps.event_timestamp,
    d.department_name,
    TIMESTAMPDIFF(HOUR, event_steps.previous_event_timestamp, event_steps.event_timestamp) AS step_duration_hours
FROM (
    SELECT
        invoice_id,
        event_name,
        event_timestamp,
        department_id,
        LAG(event_name) OVER (
            PARTITION BY invoice_id
            ORDER BY event_timestamp
        ) AS previous_event_name,
        LAG(event_timestamp) OVER (
            PARTITION BY invoice_id
            ORDER BY event_timestamp
        ) AS previous_event_timestamp
    FROM invoice_events
) event_steps
INNER JOIN departments d
    ON event_steps.department_id = d.department_id
WHERE event_steps.previous_event_timestamp IS NOT NULL
ORDER BY
    event_steps.invoice_id,
    event_steps.event_timestamp;


-- ============================================================
-- 6. Average duration by process transition
-- Main bottleneck analysis by process step.
-- ============================================================

WITH process_steps AS (
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
    previous_event_name,
    event_name,
    COUNT(*) AS number_of_cases,
    ROUND(AVG(TIMESTAMPDIFF(HOUR, previous_event_timestamp, event_timestamp)), 2) AS avg_step_duration_hours,
    MIN(TIMESTAMPDIFF(HOUR, previous_event_timestamp, event_timestamp)) AS min_step_duration_hours,
    MAX(TIMESTAMPDIFF(HOUR, previous_event_timestamp, event_timestamp)) AS max_step_duration_hours
FROM process_steps
WHERE previous_event_timestamp IS NOT NULL
GROUP BY
    previous_event_name,
    event_name
ORDER BY
    avg_step_duration_hours DESC;


-- ============================================================
-- 7. Rank process bottlenecks
-- Demonstrates RANK window function.
-- ============================================================

WITH process_steps AS (
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
),

step_durations AS (
    SELECT
        previous_event_name,
        event_name,
        COUNT(*) AS number_of_cases,
        ROUND(AVG(TIMESTAMPDIFF(HOUR, previous_event_timestamp, event_timestamp)), 2) AS avg_step_duration_hours
    FROM process_steps
    WHERE previous_event_timestamp IS NOT NULL
    GROUP BY
        previous_event_name,
        event_name
)

SELECT
    RANK() OVER (
        ORDER BY avg_step_duration_hours DESC
    ) AS bottleneck_rank,
    previous_event_name,
    event_name,
    number_of_cases,
    avg_step_duration_hours
FROM step_durations
ORDER BY
    bottleneck_rank;


-- ============================================================
-- 8. Average process duration by invoice
-- Measures time from first event to last event.
-- ============================================================

SELECT
    i.invoice_id,
    i.invoice_number,
    v.vendor_name,
    i.invoice_status,
    MIN(ie.event_timestamp) AS first_event_timestamp,
    MAX(ie.event_timestamp) AS last_event_timestamp,
    TIMESTAMPDIFF(HOUR, MIN(ie.event_timestamp), MAX(ie.event_timestamp)) AS total_process_duration_hours,
    ROUND(TIMESTAMPDIFF(HOUR, MIN(ie.event_timestamp), MAX(ie.event_timestamp)) / 24, 2) AS total_process_duration_days
FROM invoices i
INNER JOIN vendors v
    ON i.vendor_id = v.vendor_id
INNER JOIN invoice_events ie
    ON i.invoice_id = ie.invoice_id
GROUP BY
    i.invoice_id,
    i.invoice_number,
    v.vendor_name,
    i.invoice_status
ORDER BY
    total_process_duration_hours DESC;


-- ============================================================
-- 9. Invoice receipt to payment scheduled duration
-- Measures internal processing time before payment scheduling.
-- ============================================================

SELECT
    i.invoice_id,
    i.invoice_number,
    v.vendor_name,
    MIN(CASE WHEN ie.event_name = 'Invoice Received' THEN ie.event_timestamp END) AS invoice_received_timestamp,
    MAX(CASE WHEN ie.event_name = 'Payment Scheduled' THEN ie.event_timestamp END) AS payment_scheduled_timestamp,
    TIMESTAMPDIFF(
        HOUR,
        MIN(CASE WHEN ie.event_name = 'Invoice Received' THEN ie.event_timestamp END),
        MAX(CASE WHEN ie.event_name = 'Payment Scheduled' THEN ie.event_timestamp END)
    ) AS receipt_to_payment_scheduled_hours
FROM invoices i
INNER JOIN vendors v
    ON i.vendor_id = v.vendor_id
INNER JOIN invoice_events ie
    ON i.invoice_id = ie.invoice_id
GROUP BY
    i.invoice_id,
    i.invoice_number,
    v.vendor_name
HAVING payment_scheduled_timestamp IS NOT NULL
ORDER BY
    receipt_to_payment_scheduled_hours DESC;


-- ============================================================
-- 10. Invoice receipt to paid duration
-- Measures full invoice-to-payment cycle time.
-- ============================================================

SELECT
    i.invoice_id,
    i.invoice_number,
    v.vendor_name,
    MIN(CASE WHEN ie.event_name = 'Invoice Received' THEN ie.event_timestamp END) AS invoice_received_timestamp,
    MAX(CASE WHEN ie.event_name = 'Paid' THEN ie.event_timestamp END) AS paid_timestamp,
    TIMESTAMPDIFF(
        HOUR,
        MIN(CASE WHEN ie.event_name = 'Invoice Received' THEN ie.event_timestamp END),
        MAX(CASE WHEN ie.event_name = 'Paid' THEN ie.event_timestamp END)
    ) AS invoice_to_payment_cycle_hours,
    ROUND(
        TIMESTAMPDIFF(
            HOUR,
            MIN(CASE WHEN ie.event_name = 'Invoice Received' THEN ie.event_timestamp END),
            MAX(CASE WHEN ie.event_name = 'Paid' THEN ie.event_timestamp END)
        ) / 24,
        2
    ) AS invoice_to_payment_cycle_days
FROM invoices i
INNER JOIN vendors v
    ON i.vendor_id = v.vendor_id
INNER JOIN invoice_events ie
    ON i.invoice_id = ie.invoice_id
GROUP BY
    i.invoice_id,
    i.invoice_number,
    v.vendor_name
HAVING paid_timestamp IS NOT NULL
ORDER BY
    invoice_to_payment_cycle_hours DESC;


-- ============================================================
-- 11. Compare standard process vs exception process
-- Measures whether exception invoices take longer.
-- ============================================================

WITH invoice_cycle_times AS (
    SELECT
        i.invoice_id,
        CASE
            WHEN i.exception_type_id IS NULL THEN 'Standard Process'
            ELSE 'Exception Process'
        END AS process_type,
        MIN(ie.event_timestamp) AS first_event_timestamp,
        MAX(ie.event_timestamp) AS last_event_timestamp,
        TIMESTAMPDIFF(HOUR, MIN(ie.event_timestamp), MAX(ie.event_timestamp)) AS total_process_duration_hours
    FROM invoices i
    INNER JOIN invoice_events ie
        ON i.invoice_id = ie.invoice_id
    GROUP BY
        i.invoice_id,
        process_type
)

SELECT
    process_type,
    COUNT(*) AS invoice_count,
    ROUND(AVG(total_process_duration_hours), 2) AS avg_process_duration_hours,
    ROUND(AVG(total_process_duration_hours) / 24, 2) AS avg_process_duration_days,
    MIN(total_process_duration_hours) AS min_process_duration_hours,
    MAX(total_process_duration_hours) AS max_process_duration_hours
FROM invoice_cycle_times
GROUP BY
    process_type
ORDER BY
    avg_process_duration_hours DESC;


-- ============================================================
-- 12. Process duration by vendor
-- Identifies vendors linked to longer processing times.
-- ============================================================

WITH invoice_cycle_times AS (
    SELECT
        i.invoice_id,
        i.vendor_id,
        TIMESTAMPDIFF(HOUR, MIN(ie.event_timestamp), MAX(ie.event_timestamp)) AS total_process_duration_hours
    FROM invoices i
    INNER JOIN invoice_events ie
        ON i.invoice_id = ie.invoice_id
    GROUP BY
        i.invoice_id,
        i.vendor_id
)

SELECT
    v.vendor_id,
    v.vendor_name,
    COUNT(ict.invoice_id) AS invoice_count,
    ROUND(AVG(ict.total_process_duration_hours), 2) AS avg_process_duration_hours,
    ROUND(AVG(ict.total_process_duration_hours) / 24, 2) AS avg_process_duration_days,
    MAX(ict.total_process_duration_hours) AS max_process_duration_hours
FROM invoice_cycle_times ict
INNER JOIN vendors v
    ON ict.vendor_id = v.vendor_id
GROUP BY
    v.vendor_id,
    v.vendor_name
ORDER BY
    avg_process_duration_hours DESC;


-- ============================================================
-- 13. Process duration by department
-- Uses invoice owner department from invoices table.
-- ============================================================

WITH invoice_cycle_times AS (
    SELECT
        i.invoice_id,
        i.department_id,
        TIMESTAMPDIFF(HOUR, MIN(ie.event_timestamp), MAX(ie.event_timestamp)) AS total_process_duration_hours
    FROM invoices i
    INNER JOIN invoice_events ie
        ON i.invoice_id = ie.invoice_id
    GROUP BY
        i.invoice_id,
        i.department_id
)

SELECT
    d.department_id,
    d.department_name,
    COUNT(ict.invoice_id) AS invoice_count,
    ROUND(AVG(ict.total_process_duration_hours), 2) AS avg_process_duration_hours,
    ROUND(AVG(ict.total_process_duration_hours) / 24, 2) AS avg_process_duration_days,
    MAX(ict.total_process_duration_hours) AS max_process_duration_hours
FROM invoice_cycle_times ict
INNER JOIN departments d
    ON ict.department_id = d.department_id
GROUP BY
    d.department_id,
    d.department_name
ORDER BY
    avg_process_duration_hours DESC;


-- ============================================================
-- 14. Approval duration by department
-- Measures time from previous event to Approval event.
-- ============================================================

WITH process_steps AS (
    SELECT
        invoice_id,
        event_name,
        event_timestamp,
        department_id,
        LAG(event_timestamp) OVER (
            PARTITION BY invoice_id
            ORDER BY event_timestamp
        ) AS previous_event_timestamp
    FROM invoice_events
)

SELECT
    d.department_id,
    d.department_name,
    COUNT(*) AS approval_event_count,
    ROUND(AVG(TIMESTAMPDIFF(HOUR, ps.previous_event_timestamp, ps.event_timestamp)), 2) AS avg_approval_step_hours,
    MAX(TIMESTAMPDIFF(HOUR, ps.previous_event_timestamp, ps.event_timestamp)) AS max_approval_step_hours
FROM process_steps ps
INNER JOIN departments d
    ON ps.department_id = d.department_id
WHERE ps.event_name = 'Approval'
  AND ps.previous_event_timestamp IS NOT NULL
GROUP BY
    d.department_id,
    d.department_name
ORDER BY
    avg_approval_step_hours DESC;


-- ============================================================
-- 15. Exception resolution duration
-- Measures time from Exception Raised to Correction Received
-- or Correction Requested.
-- ============================================================

WITH exception_events AS (
    SELECT
        invoice_id,
        MIN(CASE WHEN event_name = 'Exception Raised' THEN event_timestamp END) AS exception_raised_timestamp,
        MIN(CASE WHEN event_name IN ('Correction Received', 'Correction Requested') THEN event_timestamp END) AS correction_timestamp
    FROM invoice_events
    GROUP BY
        invoice_id
)

SELECT
    i.invoice_id,
    i.invoice_number,
    v.vendor_name,
    et.exception_name,
    exception_raised_timestamp,
    correction_timestamp,
    TIMESTAMPDIFF(HOUR, exception_raised_timestamp, correction_timestamp) AS exception_resolution_hours,
    ROUND(TIMESTAMPDIFF(HOUR, exception_raised_timestamp, correction_timestamp) / 24, 2) AS exception_resolution_days
FROM exception_events ee
INNER JOIN invoices i
    ON ee.invoice_id = i.invoice_id
INNER JOIN vendors v
    ON i.vendor_id = v.vendor_id
LEFT JOIN exception_types et
    ON i.exception_type_id = et.exception_type_id
WHERE exception_raised_timestamp IS NOT NULL
  AND correction_timestamp IS NOT NULL
ORDER BY
    exception_resolution_hours DESC;


-- ============================================================
-- 16. Exception resolution by exception type
-- Identifies which exception types take longest.
-- ============================================================

WITH exception_events AS (
    SELECT
        invoice_id,
        MIN(CASE WHEN event_name = 'Exception Raised' THEN event_timestamp END) AS exception_raised_timestamp,
        MIN(CASE WHEN event_name IN ('Correction Received', 'Correction Requested') THEN event_timestamp END) AS correction_timestamp
    FROM invoice_events
    GROUP BY
        invoice_id
),

exception_durations AS (
    SELECT
        i.invoice_id,
        i.exception_type_id,
        TIMESTAMPDIFF(HOUR, ee.exception_raised_timestamp, ee.correction_timestamp) AS exception_resolution_hours
    FROM exception_events ee
    INNER JOIN invoices i
        ON ee.invoice_id = i.invoice_id
    WHERE ee.exception_raised_timestamp IS NOT NULL
      AND ee.correction_timestamp IS NOT NULL
)

SELECT
    et.exception_name,
    et.exception_category,
    COUNT(ed.invoice_id) AS exception_count,
    ROUND(AVG(ed.exception_resolution_hours), 2) AS avg_exception_resolution_hours,
    ROUND(AVG(ed.exception_resolution_hours) / 24, 2) AS avg_exception_resolution_days,
    MAX(ed.exception_resolution_hours) AS max_exception_resolution_hours,
    et.standard_resolution_days
FROM exception_durations ed
INNER JOIN exception_types et
    ON ed.exception_type_id = et.exception_type_id
GROUP BY
    et.exception_name,
    et.exception_category,
    et.standard_resolution_days
ORDER BY
    avg_exception_resolution_hours DESC;


-- ============================================================
-- 17. Identify open process cases
-- Shows invoices where the latest event is not Paid.
-- ============================================================

WITH latest_events AS (
    SELECT
        invoice_id,
        event_name,
        event_timestamp,
        event_status,
        ROW_NUMBER() OVER (
            PARTITION BY invoice_id
            ORDER BY event_timestamp DESC
        ) AS latest_event_rank
    FROM invoice_events
)

SELECT
    i.invoice_id,
    i.invoice_number,
    v.vendor_name,
    i.invoice_status,
    le.event_name AS latest_event_name,
    le.event_timestamp AS latest_event_timestamp,
    le.event_status AS latest_event_status
FROM latest_events le
INNER JOIN invoices i
    ON le.invoice_id = i.invoice_id
INNER JOIN vendors v
    ON i.vendor_id = v.vendor_id
WHERE le.latest_event_rank = 1
  AND le.event_name <> 'Paid'
ORDER BY
    le.event_timestamp;


-- ============================================================
-- 18. Identify invoices currently waiting for action
-- Uses pending event status.
-- ============================================================

SELECT
    i.invoice_id,
    i.invoice_number,
    v.vendor_name,
    d.department_name,
    ie.event_name,
    ie.event_timestamp,
    ie.event_status
FROM invoice_events ie
INNER JOIN invoices i
    ON ie.invoice_id = i.invoice_id
INNER JOIN vendors v
    ON i.vendor_id = v.vendor_id
INNER JOIN departments d
    ON ie.department_id = d.department_id
WHERE ie.event_status = 'Pending'
ORDER BY
    ie.event_timestamp;


-- ============================================================
-- 19. Create process variants per invoice
-- Demonstrates GROUP_CONCAT ordered by event timestamp.
-- ============================================================

SELECT
    i.invoice_id,
    i.invoice_number,
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
    i.invoice_number
ORDER BY
    i.invoice_id;


-- ============================================================
-- 20. Count process variants
-- Identifies standard and non-standard process paths.
-- ============================================================

WITH process_variants AS (
    SELECT
        i.invoice_id,
        GROUP_CONCAT(
            ie.event_name
            ORDER BY ie.event_timestamp
            SEPARATOR ' > '
        ) AS process_variant
    FROM invoices i
    INNER JOIN invoice_events ie
        ON i.invoice_id = ie.invoice_id
    GROUP BY
        i.invoice_id
)

SELECT
    process_variant,
    COUNT(*) AS invoice_count
FROM process_variants
GROUP BY
    process_variant
ORDER BY
    invoice_count DESC;


-- ============================================================
-- 21. Process variant performance
-- Combines process variants with duration.
-- ============================================================

WITH process_variants AS (
    SELECT
        i.invoice_id,
        GROUP_CONCAT(
            ie.event_name
            ORDER BY ie.event_timestamp
            SEPARATOR ' > '
        ) AS process_variant
    FROM invoices i
    INNER JOIN invoice_events ie
        ON i.invoice_id = ie.invoice_id
    GROUP BY
        i.invoice_id
),

invoice_cycle_times AS (
    SELECT
        invoice_id,
        TIMESTAMPDIFF(HOUR, MIN(event_timestamp), MAX(event_timestamp)) AS total_process_duration_hours
    FROM invoice_events
    GROUP BY
        invoice_id
)

SELECT
    pv.process_variant,
    COUNT(*) AS invoice_count,
    ROUND(AVG(ict.total_process_duration_hours), 2) AS avg_process_duration_hours,
    ROUND(AVG(ict.total_process_duration_hours) / 24, 2) AS avg_process_duration_days
FROM process_variants pv
INNER JOIN invoice_cycle_times ict
    ON pv.invoice_id = ict.invoice_id
GROUP BY
    pv.process_variant
ORDER BY
    avg_process_duration_hours DESC;


-- ============================================================
-- 22. Bottleneck analysis by department
-- Uses the department responsible for the current event.
-- ============================================================

WITH process_steps AS (
    SELECT
        invoice_id,
        event_name,
        event_timestamp,
        department_id,
        LAG(event_timestamp) OVER (
            PARTITION BY invoice_id
            ORDER BY event_timestamp
        ) AS previous_event_timestamp
    FROM invoice_events
)

SELECT
    d.department_id,
    d.department_name,
    COUNT(*) AS step_count,
    ROUND(AVG(TIMESTAMPDIFF(HOUR, ps.previous_event_timestamp, ps.event_timestamp)), 2) AS avg_step_duration_hours,
    MAX(TIMESTAMPDIFF(HOUR, ps.previous_event_timestamp, ps.event_timestamp)) AS max_step_duration_hours
FROM process_steps ps
INNER JOIN departments d
    ON ps.department_id = d.department_id
WHERE ps.previous_event_timestamp IS NOT NULL
GROUP BY
    d.department_id,
    d.department_name
ORDER BY
    avg_step_duration_hours DESC;


-- ============================================================
-- 23. Top 10 slowest individual process steps
-- Identifies extreme cases.
-- ============================================================

WITH process_steps AS (
    SELECT
        invoice_id,
        event_name,
        event_timestamp,
        department_id,
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
    ps.invoice_id,
    i.invoice_number,
    v.vendor_name,
    ps.previous_event_name,
    ps.event_name,
    d.department_name,
    ps.previous_event_timestamp,
    ps.event_timestamp,
    TIMESTAMPDIFF(HOUR, ps.previous_event_timestamp, ps.event_timestamp) AS step_duration_hours
FROM process_steps ps
INNER JOIN invoices i
    ON ps.invoice_id = i.invoice_id
INNER JOIN vendors v
    ON i.vendor_id = v.vendor_id
INNER JOIN departments d
    ON ps.department_id = d.department_id
WHERE ps.previous_event_timestamp IS NOT NULL
ORDER BY
    step_duration_hours DESC
LIMIT 10;


-- ============================================================
-- 24. SLA classification for invoice processing
-- Defines internal processing SLA as:
-- Payment Scheduled within 7 days after Invoice Received.
-- ============================================================

WITH receipt_to_schedule AS (
    SELECT
        invoice_id,
        MIN(CASE WHEN event_name = 'Invoice Received' THEN event_timestamp END) AS invoice_received_timestamp,
        MAX(CASE WHEN event_name = 'Payment Scheduled' THEN event_timestamp END) AS payment_scheduled_timestamp
    FROM invoice_events
    GROUP BY
        invoice_id
)

SELECT
    i.invoice_id,
    i.invoice_number,
    v.vendor_name,
    invoice_received_timestamp,
    payment_scheduled_timestamp,
    TIMESTAMPDIFF(DAY, invoice_received_timestamp, payment_scheduled_timestamp) AS processing_days,
    CASE
        WHEN payment_scheduled_timestamp IS NULL THEN 'Not Scheduled Yet'
        WHEN TIMESTAMPDIFF(DAY, invoice_received_timestamp, payment_scheduled_timestamp) <= 7 THEN 'Within SLA'
        ELSE 'SLA Breach'
    END AS processing_sla_status
FROM receipt_to_schedule rts
INNER JOIN invoices i
    ON rts.invoice_id = i.invoice_id
INNER JOIN vendors v
    ON i.vendor_id = v.vendor_id
ORDER BY
    processing_days DESC;


-- ============================================================
-- 25. SLA breach rate
-- Management-level KPI for processing timeliness.
-- ============================================================

WITH receipt_to_schedule AS (
    SELECT
        invoice_id,
        MIN(CASE WHEN event_name = 'Invoice Received' THEN event_timestamp END) AS invoice_received_timestamp,
        MAX(CASE WHEN event_name = 'Payment Scheduled' THEN event_timestamp END) AS payment_scheduled_timestamp
    FROM invoice_events
    GROUP BY
        invoice_id
),

sla_classification AS (
    SELECT
        invoice_id,
        CASE
            WHEN payment_scheduled_timestamp IS NULL THEN 'Not Scheduled Yet'
            WHEN TIMESTAMPDIFF(DAY, invoice_received_timestamp, payment_scheduled_timestamp) <= 7 THEN 'Within SLA'
            ELSE 'SLA Breach'
        END AS processing_sla_status
    FROM receipt_to_schedule
)

SELECT
    processing_sla_status,
    COUNT(*) AS invoice_count,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM sla_classification) * 100, 2) AS share_of_invoices_percent
FROM sla_classification
GROUP BY
    processing_sla_status
ORDER BY
    invoice_count DESC;


-- ============================================================
-- 26. SLA status by vendor
-- Identifies vendors linked to slow processing.
-- ============================================================

WITH receipt_to_schedule AS (
    SELECT
        invoice_id,
        MIN(CASE WHEN event_name = 'Invoice Received' THEN event_timestamp END) AS invoice_received_timestamp,
        MAX(CASE WHEN event_name = 'Payment Scheduled' THEN event_timestamp END) AS payment_scheduled_timestamp
    FROM invoice_events
    GROUP BY
        invoice_id
),

sla_classification AS (
    SELECT
        invoice_id,
        CASE
            WHEN payment_scheduled_timestamp IS NULL THEN 'Not Scheduled Yet'
            WHEN TIMESTAMPDIFF(DAY, invoice_received_timestamp, payment_scheduled_timestamp) <= 7 THEN 'Within SLA'
            ELSE 'SLA Breach'
        END AS processing_sla_status
    FROM receipt_to_schedule
)

SELECT
    v.vendor_id,
    v.vendor_name,
    COUNT(i.invoice_id) AS invoice_count,
    SUM(CASE WHEN sc.processing_sla_status = 'Within SLA' THEN 1 ELSE 0 END) AS within_sla_count,
    SUM(CASE WHEN sc.processing_sla_status = 'SLA Breach' THEN 1 ELSE 0 END) AS sla_breach_count,
    SUM(CASE WHEN sc.processing_sla_status = 'Not Scheduled Yet' THEN 1 ELSE 0 END) AS not_scheduled_count
FROM sla_classification sc
INNER JOIN invoices i
    ON sc.invoice_id = i.invoice_id
INNER JOIN vendors v
    ON i.vendor_id = v.vendor_id
GROUP BY
    v.vendor_id,
    v.vendor_name
ORDER BY
    sla_breach_count DESC,
    not_scheduled_count DESC;


-- ============================================================
-- 27. Process analysis summary
-- Compact KPI view of process performance.
-- ============================================================

WITH invoice_cycle_times AS (
    SELECT
        invoice_id,
        TIMESTAMPDIFF(HOUR, MIN(event_timestamp), MAX(event_timestamp)) AS total_process_duration_hours
    FROM invoice_events
    GROUP BY
        invoice_id
),

process_classification AS (
    SELECT
        i.invoice_id,
        CASE
            WHEN i.exception_type_id IS NULL THEN 'Standard Process'
            ELSE 'Exception Process'
        END AS process_type
    FROM invoices i
)

SELECT
    COUNT(*) AS invoices_with_events,
    ROUND(AVG(ict.total_process_duration_hours), 2) AS avg_total_process_duration_hours,
    ROUND(AVG(ict.total_process_duration_hours) / 24, 2) AS avg_total_process_duration_days,
    SUM(CASE WHEN pc.process_type = 'Exception Process' THEN 1 ELSE 0 END) AS exception_process_count,
    SUM(CASE WHEN pc.process_type = 'Standard Process' THEN 1 ELSE 0 END) AS standard_process_count
FROM invoice_cycle_times ict
INNER JOIN process_classification pc
    ON ict.invoice_id = pc.invoice_id;