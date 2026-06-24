# KPI Definitions

## 1. Overview

This document defines the key performance indicators used in the Invoice-to-Payment Process Analysis project.

The KPI framework is designed to evaluate the process from three perspectives:

* Financial exposure and payment control
* Operational process efficiency
* Exception, vendor, and department performance

The calculations are based on the project’s MySQL data model, analytical views, and timestamped process events.

## 2. KPI Design Principles

The KPI framework follows these principles:

* KPIs should be based on reproducible SQL logic.
* Financial and operational indicators should be evaluated together.
* Completed process cases and open process cases should be interpreted separately.
* Process delays should be measured using actual event timestamps.
* Exception cases should be evaluated by frequency, duration, and financial impact.
* Vendor and department performance should be compared using consistent definitions.
* SLA thresholds are illustrative because the dataset is synthetic.

## 3. Invoice Volume and Financial Exposure

### Total Invoices

**Definition:**
The total number of invoices included in the analysis.

**Calculation:**

```text id="w6m5d8"
COUNT(invoice_id)
```

**Business Purpose:**
Measures the workload processed by Accounts Payable and provides the denominator for several rate-based KPIs.

---

### Total Invoice Amount

**Definition:**
The total financial value of all invoices in the dataset.

**Calculation:**

```text id="c80vrp"
SUM(invoice_amount)
```

**Business Purpose:**
Measures the financial volume processed through the Invoice-to-Payment workflow.

---

### Average Invoice Amount

**Definition:**
The average financial value per invoice.

**Calculation:**

```text id="cojtb5"
AVG(invoice_amount)
```

**Business Purpose:**
Provides context for the typical size of processed invoices and helps distinguish high-value from low-value process cases.

---

### Open Invoice Count

**Definition:**
The number of invoices that have not yet been paid.

**Calculation:**

```text id="0r7i4w"
COUNT(invoices where payment_status = 'Open')
```

**Business Purpose:**
Identifies unresolved payment cases that still require operational follow-up.

---

### Open Invoice Amount

**Definition:**
The total financial value of unpaid invoices.

**Calculation:**

```text id="odto3x"
SUM(invoice_amount where payment_status = 'Open')
```

**Business Purpose:**
Measures current open liability exposure and helps prioritize high-value unresolved cases.

## 4. Payment Performance KPIs

### Payment Timing

**Definition:**
A payment classification based on the relationship between the actual payment date and the internally scheduled payment date.

**Possible Categories:**

* Paid Early
* Paid On Time
* Paid Late
* Open

**Business Purpose:**
Provides a simple operational view of payment execution quality.

---

### Payment Delay Days

**Definition:**
The number of days between the scheduled payment date and the actual payment date.

**Calculation:**

```text id="f7nnkj"
DATEDIFF(actual_payment_date, scheduled_payment_date)
```

**Interpretation:**

* Negative value: payment completed before schedule
* Zero: payment completed on schedule
* Positive value: payment completed after schedule
* `NULL`: payment has not yet been completed

**Business Purpose:**
Measures the timing deviation of individual payments.

---

### Late Payment Count

**Definition:**
The number of payments completed after the scheduled payment date.

**Calculation:**

```text id="6w6bqd"
COUNT(actual_payment_date > scheduled_payment_date)
```

**Business Purpose:**
Identifies payment execution issues and delayed payment cases.

---

### Late Payment Rate

**Definition:**
The proportion of all payments that were completed late.

**Calculation:**

```text id="028brb"
Late Payments / Total Payments
```

**Business Purpose:**
Measures the reliability of payment scheduling and execution.

---

### Average Late Payment Delay

**Definition:**
The average delay, in days, among late payments only.

**Calculation:**

```text id="thqs9x"
AVG(payment_delay_days where payment_delay_days > 0)
```

**Business Purpose:**
Shows whether late payments are minor deviations or material operational delays.

## 5. Process Efficiency KPIs

### Receipt-to-Payment-Scheduled Time

**Definition:**
The time required to process an invoice internally from receipt until payment scheduling.

**Calculation:**

```text id="kba53q"
Payment Scheduled Timestamp - Invoice Received Timestamp
```

**Data Source:**
`invoice_events`

**Business Purpose:**
Measures internal processing efficiency before payment execution.

---

### Invoice-to-Payment Cycle Time

**Definition:**
The total duration from invoice receipt until the invoice is marked as paid.

**Calculation:**

```text id="i3omkz"
Paid Timestamp - Invoice Received Timestamp
```

**Data Source:**
`invoice_events`

**Business Purpose:**
Measures end-to-end completion time for closed process cases.

**Important Note:**
This KPI should only be calculated for invoices with a recorded `Paid` event.

---

### Open Case Age

**Definition:**
The elapsed time between invoice receipt and the latest recorded event for an unfinished process case.

**Calculation:**

```text id="y2g0w5"
Latest Event Timestamp - Invoice Received Timestamp
```

**Business Purpose:**
Measures how long unresolved invoices have been waiting in the workflow.

**Important Note:**
Open case age is not a completed cycle time. It should be interpreted as current process duration.

---

### Average Process Step Duration

**Definition:**
The average duration between two consecutive workflow events.

**Calculation:**

```text id="l686u2"
AVG(Current Event Timestamp - Previous Event Timestamp)
```

**Data Source:**
`invoice_events`, using `LAG()` and `TIMESTAMPDIFF()`

**Business Purpose:**
Identifies delays between specific process transitions.

---

### Bottleneck Duration

**Definition:**
The average duration of a specific process transition across all relevant invoices.

**Examples:**

* Data Validation → PO Matching
* PO Matching → Approval
* Approval → Payment Scheduled
* Payment Scheduled → Paid
* Exception Raised → Correction Received

**Business Purpose:**
Highlights workflow stages with the highest waiting time and greatest optimization potential.

## 6. Exception Handling KPIs

### Exception Invoice Count

**Definition:**
The number of invoices with an assigned exception type.

**Calculation:**

```text id="minarw"
COUNT(exception_type_id IS NOT NULL)
```

**Business Purpose:**
Measures the volume of non-standard processing cases.

---

### Exception Rate

**Definition:**
The share of invoices that require exception handling.

**Calculation:**

```text id="56l3xa"
Exception Invoices / Total Invoices
```

**Business Purpose:**
Indicates the stability of the core process. A high rate may point to weak purchase order quality, inconsistent vendor data, or inadequate process standardization.

---

### Exception Resolution Time

**Definition:**
The duration between the `Exception Raised` event and a correction-related event.

**Calculation:**

```text id="zdl6ng"
Correction Timestamp - Exception Raised Timestamp
```

**Relevant Correction Events:**

* Correction Received
* Correction Requested

**Business Purpose:**
Measures how quickly exception cases are addressed.

---

### Average Exception Resolution Time

**Definition:**
The average time required to progress from an exception to a correction-related event.

**Calculation:**

```text id="bm3i1x"
AVG(Exception Resolution Time)
```

**Business Purpose:**
Helps prioritize exception types that create the longest processing delays.

---

### Exception Impact Amount

**Definition:**
The total invoice value associated with exception cases.

**Calculation:**

```text id="0eyg7r"
SUM(invoice_amount for invoices with exception_type_id)
```

**Business Purpose:**
Distinguishes frequent low-value exceptions from financially material issues.

## 7. Vendor Performance KPIs

### Vendor Invoice Volume

**Definition:**
The number of invoices associated with a vendor.

**Calculation:**

```text id="wdlwny"
COUNT(invoice_id grouped by vendor)
```

**Business Purpose:**
Measures the operational workload generated by each vendor.

---

### Vendor Invoice Amount

**Definition:**
The total invoice amount associated with a vendor.

**Calculation:**

```text id="e3awex"
SUM(invoice_amount grouped by vendor)
```

**Business Purpose:**
Measures the financial relevance of each vendor relationship.

---

### Vendor Exception Rate

**Definition:**
The share of a vendor’s invoices that include an exception.

**Calculation:**

```text id="08akcy"
Vendor Exception Invoices / Vendor Total Invoices
```

**Business Purpose:**
Identifies vendors associated with recurring invoice quality or matching issues.

---

### Vendor Open Invoice Amount

**Definition:**
The value of unpaid invoices associated with a vendor.

**Calculation:**

```text id="c3fukl"
SUM(open invoice amount grouped by vendor)
```

**Business Purpose:**
Identifies vendor relationships with unresolved financial exposure.

---

### Vendor Average Cycle Time

**Definition:**
The average completed Invoice-to-Payment cycle time for a vendor.

**Calculation:**

```text id="bb123a"
AVG(invoice-to-payment cycle time grouped by vendor)
```

**Business Purpose:**
Identifies vendors that are associated with longer process execution times.

---

### Vendor Performance Category

**Definition:**
A rule-based classification of vendors based on exception rate, open invoice exposure, late payment performance, and average cycle time.

**Possible Categories:**

* Reliable
* Needs Monitoring
* Critical

**Business Purpose:**
Converts multiple operational metrics into a management-oriented prioritization category.

## 8. Department Performance KPIs

### Department Invoice Volume

**Definition:**
The number of invoices assigned to each department.

**Calculation:**

```text id="c7hdb2"
COUNT(invoice_id grouped by department)
```

**Business Purpose:**
Measures invoice ownership and workload distribution.

---

### Department Event Volume

**Definition:**
The number of workflow events handled by each department.

**Calculation:**

```text id="qu37yw"
COUNT(event_id grouped by department)
```

**Business Purpose:**
Measures operational activity within the workflow.

---

### Average Department Step Duration

**Definition:**
The average duration of process steps assigned to a department.

**Calculation:**

```text id="dsv7jk"
AVG(step duration grouped by department)
```

**Business Purpose:**
Identifies departments associated with extended process waiting times.

---

### Approval Waiting Time

**Definition:**
The average duration between the event preceding approval and the approval event itself.

**Calculation:**

```text id="x6qmsu"
AVG(Approval Timestamp - Previous Event Timestamp)
```

**Business Purpose:**
Measures approval responsiveness and helps identify approval-related bottlenecks.

---

### Open Invoice Exposure by Department

**Definition:**
The total invoice value of unpaid invoices owned by a department.

**Calculation:**

```text id="4j5qil"
SUM(open invoice amount grouped by department)
```

**Business Purpose:**
Helps prioritize operational follow-up across departments.

## 9. SLA Performance KPIs

### Internal Processing SLA

**Definition:**
The project defines the internal target as payment scheduling within seven days after invoice receipt.

**Threshold:**

```text id="a2zjwq"
Receipt-to-Payment-Scheduled Time <= 168 hours
```

**Business Purpose:**
Creates a consistent benchmark for evaluating processing timeliness.

---

### SLA Compliance Rate

**Definition:**
The share of invoices that are scheduled for payment within the internal SLA threshold.

**Calculation:**

```text id="i1wq8c"
Invoices Within SLA / All Invoices
```

**Business Purpose:**
Measures process reliability and timeliness.

---

### SLA Breach Count

**Definition:**
The number of invoices for which payment scheduling exceeded seven days after receipt.

**Calculation:**

```text id="s7zv11"
COUNT(receipt-to-payment-scheduled time > 168 hours)
```

**Business Purpose:**
Identifies process cases that require review.

---

### Not Scheduled Yet Count

**Definition:**
The number of invoices without a `Payment Scheduled` event.

**Calculation:**

```text id="rkn68p"
COUNT(payment_scheduled_timestamp IS NULL)
```

**Business Purpose:**
Highlights unresolved process cases that remain in the workflow.

## 10. Process Variant KPIs

### Process Variant

**Definition:**
The ordered event sequence followed by an invoice.

**Calculation:**

```text id="okezbt"
GROUP_CONCAT(event_name ORDER BY event_timestamp)
```

**Business Purpose:**
Makes standard and non-standard workflow paths visible.

---

### Variant Frequency

**Definition:**
The number of invoices following the same process sequence.

**Calculation:**

```text id="4turav"
COUNT(invoices grouped by process variant)
```

**Business Purpose:**
Identifies dominant workflow paths and unusual process deviations.

---

### Variant Cycle Time

**Definition:**
The average Invoice-to-Payment cycle time for invoices following a specific process variant.

**Calculation:**

```text id="rckqmp"
AVG(cycle time grouped by process variant)
```

**Business Purpose:**
Identifies process paths that are operationally inefficient.

---

### Standard Process Share

**Definition:**
The share of invoices processed without an exception type.

**Calculation:**

```text id="s464o6"
Standard Process Invoices / Total Invoices
```

**Business Purpose:**
Measures the degree of process standardization.

---

### Exception Process Share

**Definition:**
The share of invoices that follow an exception-driven process.

**Calculation:**

```text id="8dpr6n"
Exception Process Invoices / Total Invoices
```

**Business Purpose:**
Measures the level of manual intervention required in the process.

## 11. KPI Interpretation Notes

The following points are important when interpreting results:

* Payment timing is measured against the internal scheduled payment date, not the contractual vendor due date.
* Completed cycle time should only be used for invoices with a recorded `Paid` event.
* Open cases should be evaluated using open case age and current process status.
* Step duration is attributed to the department responsible for the current event.
* Purchase order and invoice amount differences are treated as review cases, not automatically as incorrect data.
* The vendor performance categories are illustrative and based on thresholds defined for this synthetic dataset.
* SLA thresholds are illustrative and are not based on a real company policy.
