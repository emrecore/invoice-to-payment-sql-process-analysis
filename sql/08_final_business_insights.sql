-- ============================================================
-- Project: Invoice-to-Payment Process Analysis with SQL
-- File: 08_final_business_insights.sql
-- Purpose: Final business-focused insights for management.
--          Uses reusable analytical views created in
--          07_create_views.sql.
-- SQL Dialect: MySQL
-- ============================================================

USE invoice_to_payment_analysis;


-- ============================================================
-- 1. Executive KPI overview
-- High-level summary of invoice, payment, exception,
-- and process performance.
-- ============================================================

SELECT
    COUNT(*) AS total_invoices,
    ROUND(SUM(invoice_amount), 2) AS total_invoice_amount,
    ROUND(AVG(invoice_amount), 2) AS average_invoice_amount,

    SUM(
        CASE
            WHEN process_type = 'Exception Process' THEN 1
            ELSE 0
        END
    ) AS exception_invoice_count,

    ROUND(
        SUM(
            CASE
                WHEN process_type = 'Exception Process' THEN 1
                ELSE 0
            END
        ) / COUNT(*) * 100,
        2
    ) AS exception_rate_percent,

    SUM(
        CASE
            WHEN payment_status = 'Open' THEN 1
            ELSE 0
        END
    ) AS open_invoice_count,

    ROUND(SUM(open_invoice_amount), 2) AS open_invoice_amount,

    SUM(
        CASE
            WHEN payment_timing = 'Paid Late' THEN 1
            ELSE 0
        END
    ) AS late_payment_count,

    ROUND(
        SUM(
            CASE
                WHEN payment_timing = 'Paid Late' THEN 1
                ELSE 0
            END
        ) / COUNT(*) * 100,
        2
    ) AS late_payment_rate_percent

FROM vw_invoice_overview;


-- ============================================================
-- 2. Process cycle time overview
-- Measures average internal and end-to-end process duration.
-- ============================================================

SELECT
    COUNT(*) AS invoices_with_process_events,

    ROUND(
        AVG(receipt_to_payment_scheduled_hours),
        2
    ) AS avg_receipt_to_payment_scheduled_hours,

    ROUND(
        AVG(receipt_to_payment_scheduled_hours) / 24,
        2
    ) AS avg_receipt_to_payment_scheduled_days,

    ROUND(
        AVG(invoice_to_payment_cycle_hours),
        2
    ) AS avg_invoice_to_payment_cycle_hours,

    ROUND(
        AVG(invoice_to_payment_cycle_days),
        2
    ) AS avg_invoice_to_payment_cycle_days

FROM vw_process_cycle_times;


-- ============================================================
-- 3. Top process bottlenecks
-- Identifies the slowest process transitions.
-- ============================================================

SELECT
    previous_event_name,
    event_name,
    COUNT(*) AS number_of_cases,

    ROUND(
        AVG(step_duration_hours),
        2
    ) AS avg_step_duration_hours,

    ROUND(
        AVG(step_duration_days),
        2
    ) AS avg_step_duration_days,

    MAX(step_duration_hours) AS max_step_duration_hours

FROM vw_process_step_durations

GROUP BY
    previous_event_name,
    event_name

ORDER BY
    avg_step_duration_hours DESC;


-- ============================================================
-- 4. Bottleneck ranking
-- Ranks process transitions by average duration.
-- ============================================================

WITH bottlenecks AS (
    SELECT
        previous_event_name,
        event_name,
        COUNT(*) AS number_of_cases,
        ROUND(AVG(step_duration_hours), 2) AS avg_step_duration_hours
    FROM vw_process_step_durations
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

FROM bottlenecks

ORDER BY
    bottleneck_rank;


-- ============================================================
-- 5. Vendor performance ranking
-- Combines invoice volume, exceptions, open amounts,
-- payment delays, and process duration.
-- ============================================================

SELECT
    vendor_id,
    vendor_name,
    vendor_category,
    risk_level,

    total_invoices,
    total_invoice_amount,

    exception_invoice_count,
    exception_rate_percent,

    open_payment_count,
    open_invoice_amount,

    late_payment_count,
    late_payment_rate_percent,

    avg_invoice_to_payment_cycle_days,

    CASE
        WHEN exception_rate_percent >= 50
            OR open_invoice_amount >= 10000
            OR avg_invoice_to_payment_cycle_days >= 25
        THEN 'Critical'

        WHEN exception_rate_percent >= 25
            OR open_invoice_amount > 0
            OR avg_invoice_to_payment_cycle_days >= 15
        THEN 'Needs Monitoring'

        ELSE 'Reliable'
    END AS vendor_performance_category

FROM vw_vendor_performance

ORDER BY
    vendor_performance_category DESC,
    open_invoice_amount DESC,
    exception_rate_percent DESC;


-- ============================================================
-- 6. Most critical vendors
-- Focuses on vendors with the greatest operational risk.
-- ============================================================

SELECT
    vendor_id,
    vendor_name,
    risk_level,
    total_invoices,
    total_invoice_amount,
    exception_rate_percent,
    open_invoice_amount,
    late_payment_rate_percent,
    avg_invoice_to_payment_cycle_days

FROM vw_vendor_performance

WHERE exception_rate_percent >= 25
   OR open_invoice_amount > 0
   OR late_payment_rate_percent > 0

ORDER BY
    open_invoice_amount DESC,
    exception_rate_percent DESC,
    late_payment_rate_percent DESC;


-- ============================================================
-- 7. Exception type impact analysis
-- Identifies which exception types affect the most invoices
-- and the largest invoice values.
-- ============================================================

SELECT
    exception_name,
    exception_category,
    COUNT(*) AS affected_invoice_count,

    ROUND(SUM(invoice_amount), 2) AS affected_invoice_amount,

    ROUND(AVG(invoice_amount), 2) AS avg_affected_invoice_amount,

    ROUND(
        COUNT(*) / (
            SELECT COUNT(*)
            FROM vw_invoice_overview
        ) * 100,
        2
    ) AS exception_share_percent

FROM vw_invoice_overview

WHERE exception_type_id IS NOT NULL

GROUP BY
    exception_name,
    exception_category

ORDER BY
    affected_invoice_amount DESC,
    affected_invoice_count DESC;


-- ============================================================
-- 8. Exception process versus standard process
-- Compares processing durations by process type.
-- ============================================================

SELECT
    process_type,
    COUNT(*) AS invoice_count,

    ROUND(
        AVG(receipt_to_payment_scheduled_hours),
        2
    ) AS avg_internal_processing_hours,

    ROUND(
        AVG(receipt_to_payment_scheduled_hours) / 24,
        2
    ) AS avg_internal_processing_days,

    ROUND(
        AVG(invoice_to_payment_cycle_days),
        2
    ) AS avg_end_to_end_cycle_days

FROM vw_process_cycle_times

GROUP BY
    process_type

ORDER BY
    avg_internal_processing_hours DESC;


-- ============================================================
-- 9. Department workload and bottleneck analysis
-- Uses the responsible department of each process event.
-- ============================================================

SELECT
    department_name,
    COUNT(*) AS process_step_count,

    ROUND(
        AVG(step_duration_hours),
        2
    ) AS avg_step_duration_hours,

    ROUND(
        AVG(step_duration_days),
        2
    ) AS avg_step_duration_days,

    MAX(step_duration_hours) AS max_step_duration_hours

FROM vw_process_step_durations

GROUP BY
    department_name

ORDER BY
    avg_step_duration_hours DESC;


-- ============================================================
-- 10. Approval bottleneck analysis
-- Evaluates the duration before approval events.
-- ============================================================

SELECT
    department_name,
    COUNT(*) AS approval_count,

    ROUND(
        AVG(step_duration_hours),
        2
    ) AS avg_approval_waiting_hours,

    ROUND(
        AVG(step_duration_days),
        2
    ) AS avg_approval_waiting_days,

    MAX(step_duration_hours) AS max_approval_waiting_hours

FROM vw_process_step_durations

WHERE event_name = 'Approval'

GROUP BY
    department_name

ORDER BY
    avg_approval_waiting_hours DESC;


-- ============================================================
-- 11. Open invoice exposure
-- Shows unpaid financial exposure by vendor and department.
-- ============================================================

SELECT
    vendor_name,
    department_name,
    COUNT(*) AS open_invoice_count,
    ROUND(SUM(invoice_amount), 2) AS open_invoice_amount

FROM vw_invoice_overview

WHERE payment_status = 'Open'

GROUP BY
    vendor_name,
    department_name

ORDER BY
    open_invoice_amount DESC;


-- ============================================================
-- 12. Late payment analysis
-- Identifies invoices paid after the scheduled payment date.
-- ============================================================

SELECT
    invoice_id,
    invoice_number,
    vendor_name,
    invoice_amount,
    scheduled_payment_date,
    actual_payment_date,
    payment_delay_days

FROM vw_payment_performance

WHERE payment_timing = 'Paid Late'

ORDER BY
    payment_delay_days DESC,
    invoice_amount DESC;


-- ============================================================
-- 13. Payment performance by vendor
-- Summarizes payment punctuality by vendor.
-- ============================================================

SELECT
    vendor_name,

    COUNT(*) AS total_invoices,

    SUM(
        CASE
            WHEN payment_timing = 'Paid Early' THEN 1
            ELSE 0
        END
    ) AS paid_early_count,

    SUM(
        CASE
            WHEN payment_timing = 'Paid On Time' THEN 1
            ELSE 0
        END
    ) AS paid_on_time_count,

    SUM(
        CASE
            WHEN payment_timing = 'Paid Late' THEN 1
            ELSE 0
        END
    ) AS paid_late_count,

    SUM(
        CASE
            WHEN payment_timing = 'Open' THEN 1
            ELSE 0
        END
    ) AS open_payment_count,

    ROUND(
        AVG(
            CASE
                WHEN payment_timing = 'Paid Late'
                THEN payment_delay_days
                ELSE NULL
            END
        ),
        2
    ) AS avg_late_payment_delay_days

FROM vw_payment_performance

GROUP BY
    vendor_name

ORDER BY
    paid_late_count DESC,
    open_payment_count DESC;


-- ============================================================
-- 14. Longest invoice processing cases
-- Identifies operational outliers.
-- ============================================================

SELECT
    invoice_id,
    invoice_number,
    vendor_name,
    department_name,
    process_type,
    invoice_status,
    invoice_to_payment_cycle_days

FROM vw_process_cycle_times

WHERE invoice_to_payment_cycle_days IS NOT NULL

ORDER BY
    invoice_to_payment_cycle_days DESC
LIMIT 10;


-- ============================================================
-- 15. Open process cases
-- Shows invoices currently stuck in the workflow.
-- ============================================================

SELECT
    invoice_id,
    invoice_number,
    vendor_name,
    invoice_owner_department,
    invoice_status,
    invoice_amount,
    process_type,
    latest_event_name,
    latest_event_timestamp,
    latest_event_status,
    latest_event_department

FROM vw_open_process_cases

ORDER BY
    latest_event_timestamp;


-- ============================================================
-- 16. Process variant ranking
-- Shows which event paths are most common.
-- ============================================================

SELECT
    process_variant,
    process_type,
    COUNT(*) AS invoice_count

FROM vw_process_variants

GROUP BY
    process_variant,
    process_type

ORDER BY
    invoice_count DESC,
    process_type;


-- ============================================================
-- 17. Process variant efficiency analysis
-- Compares paths by average cycle time.
-- ============================================================

SELECT
    pv.process_variant,
    pv.process_type,

    COUNT(*) AS invoice_count,

    ROUND(
        AVG(pct.invoice_to_payment_cycle_days),
        2
    ) AS avg_invoice_to_payment_cycle_days,

    ROUND(
        AVG(pct.receipt_to_payment_scheduled_hours) / 24,
        2
    ) AS avg_internal_processing_days

FROM vw_process_variants pv
INNER JOIN vw_process_cycle_times pct
    ON pv.invoice_id = pct.invoice_id

GROUP BY
    pv.process_variant,
    pv.process_type

ORDER BY
    avg_invoice_to_payment_cycle_days DESC;


-- ============================================================
-- 18. Process SLA overview
-- SLA definition:
-- Payment must be scheduled within 7 days after receipt.
-- ============================================================

SELECT
    CASE
        WHEN receipt_to_payment_scheduled_hours IS NULL
            THEN 'Not Scheduled Yet'

        WHEN receipt_to_payment_scheduled_hours <= 168
            THEN 'Within SLA'

        ELSE 'SLA Breach'
    END AS processing_sla_status,

    COUNT(*) AS invoice_count,

    ROUND(
        COUNT(*) / (
            SELECT COUNT(*)
            FROM vw_process_cycle_times
        ) * 100,
        2
    ) AS share_of_invoices_percent

FROM vw_process_cycle_times

GROUP BY
    processing_sla_status

ORDER BY
    invoice_count DESC;


-- ============================================================
-- 19. SLA breaches by vendor
-- Identifies vendors linked to slow internal processing.
-- ============================================================

SELECT
    vendor_name,

    COUNT(*) AS invoice_count,

    SUM(
        CASE
            WHEN receipt_to_payment_scheduled_hours > 168 THEN 1
            ELSE 0
        END
    ) AS sla_breach_count,

    SUM(
        CASE
            WHEN receipt_to_payment_scheduled_hours IS NULL THEN 1
            ELSE 0
        END
    ) AS not_scheduled_count,

    ROUND(
        SUM(
            CASE
                WHEN receipt_to_payment_scheduled_hours > 168 THEN 1
                ELSE 0
            END
        ) / COUNT(*) * 100,
        2
    ) AS sla_breach_rate_percent

FROM vw_process_cycle_times

GROUP BY
    vendor_name

ORDER BY
    sla_breach_rate_percent DESC,
    not_scheduled_count DESC;


-- ============================================================
-- 20. Final optimization opportunity summary
-- Combines operational risks into a prioritization table.
-- ============================================================

SELECT
    vendor_name,
    total_invoices,
    total_invoice_amount,
    exception_rate_percent,
    open_invoice_amount,
    late_payment_rate_percent,
    avg_invoice_to_payment_cycle_days,

    CASE
        WHEN open_invoice_amount >= 10000
             AND exception_rate_percent >= 50
        THEN 'High Priority'

        WHEN open_invoice_amount > 0
             OR exception_rate_percent >= 50
             OR avg_invoice_to_payment_cycle_days >= 25
        THEN 'Medium Priority'

        ELSE 'Low Priority'
    END AS optimization_priority,

    CASE
        WHEN exception_rate_percent >= 50
            THEN 'Review vendor master data and PO matching quality'

        WHEN open_invoice_amount >= 10000
            THEN 'Prioritize resolution of open invoices and approvals'

        WHEN avg_invoice_to_payment_cycle_days >= 25
            THEN 'Review approval workflow and exception handling'

        WHEN late_payment_rate_percent > 0
            THEN 'Review payment scheduling process'

        ELSE 'No immediate action required'
    END AS recommended_focus_area

FROM vw_vendor_performance

ORDER BY
    optimization_priority DESC,
    open_invoice_amount DESC,
    exception_rate_percent DESC;