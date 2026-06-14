-- ============================================================
-- Project: Invoice-to-Payment Process Analysis with SQL
-- File: 02_insert_sample_data.sql
-- Purpose: Insert realistic synthetic sample data
-- SQL Dialect: MySQL
-- ============================================================

USE invoice_to_payment_analysis;


-- ============================================================
-- 1. Insert vendors
-- ============================================================

INSERT INTO vendors 
(vendor_id, vendor_name, country, vendor_category, payment_terms_days, risk_level)
VALUES
(1, 'Müller Packaging GmbH', 'Germany', 'Packaging', 30, 'Low'),
(2, 'NordTech Components GmbH', 'Germany', 'Electronics', 30, 'Medium'),
(3, 'Alpine Office Supplies AG', 'Austria', 'Office Supplies', 14, 'Low'),
(4, 'LogiTrans Europe B.V.', 'Netherlands', 'Logistics', 21, 'Medium'),
(5, 'DataServe Solutions Ltd.', 'Ireland', 'IT Services', 30, 'Low'),
(6, 'PrintPro Medien GmbH', 'Germany', 'Marketing Services', 14, 'Medium'),
(7, 'SteelWorks Industrial Sp. z o.o.', 'Poland', 'Raw Materials', 45, 'High'),
(8, 'CleanFacility Services GmbH', 'Germany', 'Facility Services', 30, 'Low');


-- ============================================================
-- 2. Insert departments
-- ============================================================

INSERT INTO departments
(department_id, department_name, cost_center, department_type)
VALUES
(1, 'Procurement', 'CC100', 'Operations'),
(2, 'Accounting', 'CC200', 'Finance'),
(3, 'IT', 'CC300', 'Support'),
(4, 'Marketing', 'CC400', 'Business'),
(5, 'Logistics', 'CC500', 'Operations'),
(6, 'Facility Management', 'CC600', 'Operations');


-- ============================================================
-- 3. Insert exception types
-- ============================================================

INSERT INTO exception_types
(exception_type_id, exception_name, exception_category, standard_resolution_days)
VALUES
(1, 'Missing Purchase Order', 'Master Data Issue', 3),
(2, 'Price Mismatch', 'Financial Mismatch', 5),
(3, 'Quantity Mismatch', 'Goods Receipt Issue', 4),
(4, 'Missing Approval', 'Approval Issue', 2),
(5, 'Duplicate Invoice Suspected', 'Data Quality Issue', 6),
(6, 'Incorrect Vendor Data', 'Master Data Issue', 3);


-- ============================================================
-- 4. Insert purchase orders
-- ============================================================

INSERT INTO purchase_orders
(po_id, vendor_id, department_id, po_date, po_amount, po_status)
VALUES
(1001, 1, 1, '2025-01-08', 4200.00, 'Closed'),
(1002, 2, 3, '2025-01-10', 8750.00, 'Closed'),
(1003, 3, 2, '2025-01-12', 950.00, 'Closed'),
(1004, 4, 5, '2025-01-15', 6200.00, 'Closed'),
(1005, 5, 3, '2025-01-18', 12000.00, 'Open'),
(1006, 6, 4, '2025-01-20', 3100.00, 'Closed'),
(1007, 7, 1, '2025-01-22', 18500.00, 'Open'),
(1008, 8, 6, '2025-01-25', 2600.00, 'Closed'),
(1009, 2, 3, '2025-02-03', 7400.00, 'Closed'),
(1010, 4, 5, '2025-02-05', 5300.00, 'Closed'),
(1011, 5, 3, '2025-02-10', 9800.00, 'Closed'),
(1012, 7, 1, '2025-02-14', 15200.00, 'Open');


-- ============================================================
-- 5. Insert invoices
-- Includes standard cases, exception cases, open invoices,
-- and one invoice without a purchase order.
-- ============================================================

INSERT INTO invoices
(invoice_id, vendor_id, po_id, department_id, invoice_number, invoice_date, received_date, invoice_amount, invoice_status, exception_type_id)
VALUES
(2001, 1, 1001, 1, 'INV-2025-001', '2025-01-10', '2025-01-11', 4200.00, 'Paid', NULL),
(2002, 2, 1002, 3, 'INV-2025-002', '2025-01-13', '2025-01-14', 8750.00, 'Paid', 2),
(2003, 3, 1003, 2, 'INV-2025-003', '2025-01-14', '2025-01-15', 950.00, 'Paid', NULL),
(2004, 4, 1004, 5, 'INV-2025-004', '2025-01-18', '2025-01-20', 6200.00, 'Paid', 3),
(2005, 5, 1005, 3, 'INV-2025-005', '2025-01-21', '2025-01-22', 12000.00, 'Approved', 4),
(2006, 6, 1006, 4, 'INV-2025-006', '2025-01-23', '2025-01-24', 3100.00, 'Paid', NULL),
(2007, 7, 1007, 1, 'INV-2025-007', '2025-01-26', '2025-01-28', 18500.00, 'In Review', 2),
(2008, 8, 1008, 6, 'INV-2025-008', '2025-01-28', '2025-01-29', 2600.00, 'Paid', NULL),
(2009, 2, 1009, 3, 'INV-2025-009', '2025-02-04', '2025-02-05', 7400.00, 'Paid', NULL),
(2010, 4, 1010, 5, 'INV-2025-010', '2025-02-07', '2025-02-10', 5300.00, 'Paid', 3),
(2011, 1, 1001, 1, 'INV-2025-011', '2025-02-12', '2025-02-13', 1800.00, 'Paid', NULL),
(2012, 5, 1005, 3, 'INV-2025-012', '2025-02-15', '2025-02-17', 4500.00, 'Approved', 1),
(2013, 6, 1006, 4, 'INV-2025-013', '2025-02-17', '2025-02-18', 2900.00, 'Paid', 5),
(2014, 7, 1007, 1, 'INV-2025-014', '2025-02-20', '2025-02-21', 9600.00, 'In Review', 2),
(2015, 8, 1008, 6, 'INV-2025-015', '2025-02-22', '2025-02-24', 2400.00, 'Paid', NULL),
(2016, 5, 1011, 3, 'INV-2025-016', '2025-03-03', '2025-03-04', 9800.00, 'Paid', NULL),
(2017, 7, 1012, 1, 'INV-2025-017', '2025-03-06', '2025-03-07', 15100.00, 'In Review', 6),
(2018, 4, NULL, 5, 'INV-2025-018', '2025-03-08', '2025-03-10', 2800.00, 'In Review', 1);


-- ============================================================
-- 6. Insert payments
-- Includes early, on-time, late, and open payments.
-- ============================================================

INSERT INTO payments
(payment_id, invoice_id, scheduled_payment_date, actual_payment_date, payment_amount, payment_status)
VALUES
(3001, 2001, '2025-02-10', '2025-02-09', 4200.00, 'Paid'),
(3002, 2002, '2025-02-13', '2025-02-20', 8750.00, 'Paid'),
(3003, 2003, '2025-01-29', '2025-01-28', 950.00, 'Paid'),
(3004, 2004, '2025-02-10', '2025-02-18', 6200.00, 'Paid'),
(3005, 2005, '2025-02-21', NULL, 0.00, 'Open'),
(3006, 2006, '2025-02-07', '2025-02-07', 3100.00, 'Paid'),
(3007, 2007, '2025-03-14', NULL, 0.00, 'Open'),
(3008, 2008, '2025-02-28', '2025-02-27', 2600.00, 'Paid'),
(3009, 2009, '2025-03-07', '2025-03-06', 7400.00, 'Paid'),
(3010, 2010, '2025-03-03', '2025-03-12', 5300.00, 'Paid'),
(3011, 2011, '2025-03-14', '2025-03-13', 1800.00, 'Paid'),
(3012, 2012, '2025-03-19', NULL, 0.00, 'Open'),
(3013, 2013, '2025-03-04', '2025-03-15', 2900.00, 'Paid'),
(3014, 2014, '2025-04-07', NULL, 0.00, 'Open'),
(3015, 2015, '2025-03-26', '2025-03-25', 2400.00, 'Paid'),
(3016, 2016, '2025-04-03', '2025-04-02', 9800.00, 'Paid'),
(3017, 2017, '2025-04-21', NULL, 0.00, 'Open'),
(3018, 2018, '2025-03-31', NULL, 0.00, 'Open');


-- ============================================================
-- 7. Insert invoice events
-- Event log for process analysis.
-- ============================================================

INSERT INTO invoice_events
(event_id, invoice_id, event_name, event_timestamp, department_id, event_status)
VALUES
-- Invoice 2001: Standard process
(4001, 2001, 'Invoice Received', '2025-01-11 09:15:00', 2, 'Completed'),
(4002, 2001, 'Data Validation', '2025-01-11 11:30:00', 2, 'Completed'),
(4003, 2001, 'PO Matching', '2025-01-12 10:00:00', 1, 'Completed'),
(4004, 2001, 'Approval', '2025-01-13 14:20:00', 1, 'Completed'),
(4005, 2001, 'Payment Scheduled', '2025-01-14 09:45:00', 2, 'Completed'),
(4006, 2001, 'Paid', '2025-02-09 16:00:00', 2, 'Completed'),

-- Invoice 2002: Price mismatch exception
(4007, 2002, 'Invoice Received', '2025-01-14 08:50:00', 2, 'Completed'),
(4008, 2002, 'Data Validation', '2025-01-14 13:10:00', 2, 'Completed'),
(4009, 2002, 'Exception Raised', '2025-01-15 09:25:00', 2, 'Completed'),
(4010, 2002, 'Correction Received', '2025-01-20 10:00:00', 3, 'Completed'),
(4011, 2002, 'PO Matching', '2025-01-21 15:30:00', 1, 'Completed'),
(4012, 2002, 'Approval', '2025-01-23 11:40:00', 3, 'Completed'),
(4013, 2002, 'Payment Scheduled', '2025-01-24 10:10:00', 2, 'Completed'),
(4014, 2002, 'Paid', '2025-02-20 15:45:00', 2, 'Completed'),

-- Invoice 2003: Standard process
(4015, 2003, 'Invoice Received', '2025-01-15 09:05:00', 2, 'Completed'),
(4016, 2003, 'Data Validation', '2025-01-15 10:25:00', 2, 'Completed'),
(4017, 2003, 'PO Matching', '2025-01-15 14:00:00', 1, 'Completed'),
(4018, 2003, 'Approval', '2025-01-16 09:40:00', 2, 'Completed'),
(4019, 2003, 'Payment Scheduled', '2025-01-16 15:00:00', 2, 'Completed'),
(4020, 2003, 'Paid', '2025-01-28 12:00:00', 2, 'Completed'),

-- Invoice 2004: Quantity mismatch exception
(4021, 2004, 'Invoice Received', '2025-01-20 10:20:00', 2, 'Completed'),
(4022, 2004, 'Data Validation', '2025-01-20 15:30:00', 2, 'Completed'),
(4023, 2004, 'Exception Raised', '2025-01-21 11:00:00', 5, 'Completed'),
(4024, 2004, 'Correction Received', '2025-01-27 09:30:00', 5, 'Completed'),
(4025, 2004, 'PO Matching', '2025-01-28 13:10:00', 1, 'Completed'),
(4026, 2004, 'Approval', '2025-01-30 16:25:00', 5, 'Completed'),
(4027, 2004, 'Payment Scheduled', '2025-01-31 09:15:00', 2, 'Completed'),
(4028, 2004, 'Paid', '2025-02-18 14:00:00', 2, 'Completed'),

-- Invoice 2005: Pending approval
(4029, 2005, 'Invoice Received', '2025-01-22 08:45:00', 2, 'Completed'),
(4030, 2005, 'Data Validation', '2025-01-22 11:15:00', 2, 'Completed'),
(4031, 2005, 'PO Matching', '2025-01-23 10:20:00', 1, 'Completed'),
(4032, 2005, 'Approval', '2025-01-28 17:45:00', 3, 'Pending'),

-- Invoice 2006: Standard process
(4033, 2006, 'Invoice Received', '2025-01-24 09:00:00', 2, 'Completed'),
(4034, 2006, 'Data Validation', '2025-01-24 12:30:00', 2, 'Completed'),
(4035, 2006, 'PO Matching', '2025-01-24 15:10:00', 1, 'Completed'),
(4036, 2006, 'Approval', '2025-01-27 10:00:00', 4, 'Completed'),
(4037, 2006, 'Payment Scheduled', '2025-01-27 14:30:00', 2, 'Completed'),
(4038, 2006, 'Paid', '2025-02-07 11:00:00', 2, 'Completed'),

-- Invoice 2007: Open exception process
(4039, 2007, 'Invoice Received', '2025-01-28 10:30:00', 2, 'Completed'),
(4040, 2007, 'Data Validation', '2025-01-29 09:50:00', 2, 'Completed'),
(4041, 2007, 'Exception Raised', '2025-01-30 14:20:00', 1, 'Completed'),
(4042, 2007, 'Correction Requested', '2025-02-03 10:00:00', 1, 'Pending'),

-- Invoice 2008: Standard process
(4043, 2008, 'Invoice Received', '2025-01-29 08:40:00', 2, 'Completed'),
(4044, 2008, 'Data Validation', '2025-01-29 10:10:00', 2, 'Completed'),
(4045, 2008, 'PO Matching', '2025-01-29 13:45:00', 1, 'Completed'),
(4046, 2008, 'Approval', '2025-01-30 11:00:00', 6, 'Completed'),
(4047, 2008, 'Payment Scheduled', '2025-01-30 16:20:00', 2, 'Completed'),
(4048, 2008, 'Paid', '2025-02-27 10:00:00', 2, 'Completed'),

-- Invoice 2009: Standard process
(4049, 2009, 'Invoice Received', '2025-02-05 09:10:00', 2, 'Completed'),
(4050, 2009, 'Data Validation', '2025-02-05 12:00:00', 2, 'Completed'),
(4051, 2009, 'PO Matching', '2025-02-06 10:30:00', 1, 'Completed'),
(4052, 2009, 'Approval', '2025-02-07 15:00:00', 3, 'Completed'),
(4053, 2009, 'Payment Scheduled', '2025-02-10 09:30:00', 2, 'Completed'),
(4054, 2009, 'Paid', '2025-03-06 13:00:00', 2, 'Completed'),

-- Invoice 2010: Quantity mismatch exception
(4055, 2010, 'Invoice Received', '2025-02-10 08:55:00', 2, 'Completed'),
(4056, 2010, 'Data Validation', '2025-02-10 11:40:00', 2, 'Completed'),
(4057, 2010, 'Exception Raised', '2025-02-11 10:10:00', 5, 'Completed'),
(4058, 2010, 'Correction Received', '2025-02-17 14:20:00', 5, 'Completed'),
(4059, 2010, 'PO Matching', '2025-02-18 09:45:00', 1, 'Completed'),
(4060, 2010, 'Approval', '2025-02-20 16:10:00', 5, 'Completed'),
(4061, 2010, 'Payment Scheduled', '2025-02-21 10:00:00', 2, 'Completed'),
(4062, 2010, 'Paid', '2025-03-12 12:30:00', 2, 'Completed'),

-- Invoice 2011: Standard process
(4063, 2011, 'Invoice Received', '2025-02-13 09:00:00', 2, 'Completed'),
(4064, 2011, 'Data Validation', '2025-02-13 10:50:00', 2, 'Completed'),
(4065, 2011, 'PO Matching', '2025-02-14 09:25:00', 1, 'Completed'),
(4066, 2011, 'Approval', '2025-02-14 15:30:00', 1, 'Completed'),
(4067, 2011, 'Payment Scheduled', '2025-02-17 11:00:00', 2, 'Completed'),
(4068, 2011, 'Paid', '2025-03-13 10:20:00', 2, 'Completed'),

-- Invoice 2012: Missing PO exception but PO was later matched
(4069, 2012, 'Invoice Received', '2025-02-17 08:30:00', 2, 'Completed'),
(4070, 2012, 'Data Validation', '2025-02-17 12:15:00', 2, 'Completed'),
(4071, 2012, 'Exception Raised', '2025-02-18 09:40:00', 2, 'Completed'),
(4072, 2012, 'Correction Received', '2025-02-21 10:30:00', 3, 'Completed'),
(4073, 2012, 'PO Matching', '2025-02-24 14:10:00', 1, 'Completed'),
(4074, 2012, 'Approval', '2025-02-26 16:45:00', 3, 'Completed'),

-- Invoice 2013: Duplicate invoice suspected
(4075, 2013, 'Invoice Received', '2025-02-18 09:20:00', 2, 'Completed'),
(4076, 2013, 'Data Validation', '2025-02-18 11:10:00', 2, 'Completed'),
(4077, 2013, 'Exception Raised', '2025-02-19 10:00:00', 2, 'Completed'),
(4078, 2013, 'Correction Received', '2025-02-26 13:30:00', 4, 'Completed'),
(4079, 2013, 'PO Matching', '2025-02-27 09:45:00', 1, 'Completed'),
(4080, 2013, 'Approval', '2025-02-28 14:40:00', 4, 'Completed'),
(4081, 2013, 'Payment Scheduled', '2025-03-03 09:30:00', 2, 'Completed'),
(4082, 2013, 'Paid', '2025-03-15 11:15:00', 2, 'Completed'),

-- Invoice 2014: Open price mismatch
(4083, 2014, 'Invoice Received', '2025-02-21 08:50:00', 2, 'Completed'),
(4084, 2014, 'Data Validation', '2025-02-21 12:25:00', 2, 'Completed'),
(4085, 2014, 'Exception Raised', '2025-02-24 10:00:00', 1, 'Completed'),
(4086, 2014, 'Correction Requested', '2025-02-26 15:20:00', 1, 'Pending'),

-- Invoice 2015: Standard process
(4087, 2015, 'Invoice Received', '2025-02-24 09:10:00', 2, 'Completed'),
(4088, 2015, 'Data Validation', '2025-02-24 11:30:00', 2, 'Completed'),
(4089, 2015, 'PO Matching', '2025-02-25 09:20:00', 1, 'Completed'),
(4090, 2015, 'Approval', '2025-02-26 10:45:00', 6, 'Completed'),
(4091, 2015, 'Payment Scheduled', '2025-02-27 09:30:00', 2, 'Completed'),
(4092, 2015, 'Paid', '2025-03-25 16:10:00', 2, 'Completed'),

-- Invoice 2016: Standard process
(4093, 2016, 'Invoice Received', '2025-03-04 09:00:00', 2, 'Completed'),
(4094, 2016, 'Data Validation', '2025-03-04 12:15:00', 2, 'Completed'),
(4095, 2016, 'PO Matching', '2025-03-05 10:30:00', 1, 'Completed'),
(4096, 2016, 'Approval', '2025-03-06 15:20:00', 3, 'Completed'),
(4097, 2016, 'Payment Scheduled', '2025-03-07 10:45:00', 2, 'Completed'),
(4098, 2016, 'Paid', '2025-04-02 13:40:00', 2, 'Completed'),

-- Invoice 2017: Incorrect vendor data
(4099, 2017, 'Invoice Received', '2025-03-07 09:25:00', 2, 'Completed'),
(4100, 2017, 'Data Validation', '2025-03-07 14:50:00', 2, 'Completed'),
(4101, 2017, 'Exception Raised', '2025-03-10 10:15:00', 2, 'Completed'),
(4102, 2017, 'Correction Requested', '2025-03-12 15:00:00', 1, 'Pending'),

-- Invoice 2018: Missing purchase order, no PO assigned
(4103, 2018, 'Invoice Received', '2025-03-10 08:35:00', 2, 'Completed'),
(4104, 2018, 'Data Validation', '2025-03-10 11:20:00', 2, 'Completed'),
(4105, 2018, 'Exception Raised', '2025-03-11 09:40:00', 5, 'Completed'),
(4106, 2018, 'Correction Requested', '2025-03-13 16:10:00', 5, 'Pending');