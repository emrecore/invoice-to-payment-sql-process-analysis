-- ============================================================
-- Project: Invoice-to-Payment Process Analysis with SQL
-- File: 01_create_tables.sql
-- Purpose: Create all database tables, primary keys,
--          foreign keys, constraints, and indexes.
-- SQL Dialect: MySQL
-- ============================================================


-- ============================================================
-- 1. Create and select database
-- ============================================================

CREATE DATABASE IF NOT EXISTS invoice_to_payment_analysis;

USE invoice_to_payment_analysis;


-- ============================================================
-- 2. Drop existing tables
-- Tables are dropped in reverse dependency order.
-- ============================================================

DROP TABLE IF EXISTS invoice_events;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS invoices;
DROP TABLE IF EXISTS purchase_orders;
DROP TABLE IF EXISTS exception_types;
DROP TABLE IF EXISTS departments;
DROP TABLE IF EXISTS vendors;


-- ============================================================
-- 3. Create table: vendors
-- Stores vendor master data.
-- ============================================================

CREATE TABLE vendors (
    vendor_id INT PRIMARY KEY,
    vendor_name VARCHAR(100) NOT NULL,
    country VARCHAR(50) NOT NULL,
    vendor_category VARCHAR(50) NOT NULL,
    payment_terms_days INT NOT NULL,
    risk_level VARCHAR(20) NOT NULL,

    CONSTRAINT chk_vendors_payment_terms
        CHECK (payment_terms_days > 0),

    CONSTRAINT chk_vendors_risk_level
        CHECK (risk_level IN ('Low', 'Medium', 'High'))
);


-- ============================================================
-- 4. Create table: departments
-- Stores internal departments and cost centers.
-- ============================================================

CREATE TABLE departments (
    department_id INT PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL,
    cost_center VARCHAR(20) NOT NULL UNIQUE,
    department_type VARCHAR(50) NOT NULL
);


-- ============================================================
-- 5. Create table: exception_types
-- Stores invoice processing exception categories.
-- ============================================================

CREATE TABLE exception_types (
    exception_type_id INT PRIMARY KEY,
    exception_name VARCHAR(100) NOT NULL,
    exception_category VARCHAR(100) NOT NULL,
    standard_resolution_days INT NOT NULL,

    CONSTRAINT chk_exception_resolution_days
        CHECK (standard_resolution_days >= 0)
);


-- ============================================================
-- 6. Create table: purchase_orders
-- Stores purchase order data linked to vendors and departments.
-- ============================================================

CREATE TABLE purchase_orders (
    po_id INT PRIMARY KEY,
    vendor_id INT NOT NULL,
    department_id INT NOT NULL,
    po_date DATE NOT NULL,
    po_amount DECIMAL(12, 2) NOT NULL,
    po_status VARCHAR(20) NOT NULL,

    CONSTRAINT fk_purchase_orders_vendor
        FOREIGN KEY (vendor_id)
        REFERENCES vendors (vendor_id),

    CONSTRAINT fk_purchase_orders_department
        FOREIGN KEY (department_id)
        REFERENCES departments (department_id),

    CONSTRAINT chk_purchase_orders_amount
        CHECK (po_amount > 0),

    CONSTRAINT chk_purchase_orders_status
        CHECK (po_status IN ('Open', 'Closed', 'Cancelled'))
);


-- ============================================================
-- 7. Create table: invoices
-- Stores invoice-level transaction data.
-- ============================================================

CREATE TABLE invoices (
    invoice_id INT PRIMARY KEY,
    vendor_id INT NOT NULL,
    po_id INT,
    department_id INT NOT NULL,
    invoice_number VARCHAR(50) NOT NULL UNIQUE,
    invoice_date DATE NOT NULL,
    received_date DATE NOT NULL,
    invoice_amount DECIMAL(12, 2) NOT NULL,
    invoice_status VARCHAR(30) NOT NULL,
    exception_type_id INT,

    CONSTRAINT fk_invoices_vendor
        FOREIGN KEY (vendor_id)
        REFERENCES vendors (vendor_id),

    CONSTRAINT fk_invoices_purchase_order
        FOREIGN KEY (po_id)
        REFERENCES purchase_orders (po_id),

    CONSTRAINT fk_invoices_department
        FOREIGN KEY (department_id)
        REFERENCES departments (department_id),

    CONSTRAINT fk_invoices_exception_type
        FOREIGN KEY (exception_type_id)
        REFERENCES exception_types (exception_type_id),

    CONSTRAINT chk_invoices_amount
        CHECK (invoice_amount > 0),

    CONSTRAINT chk_invoices_dates
        CHECK (received_date >= invoice_date),

    CONSTRAINT chk_invoices_status
        CHECK (invoice_status IN ('Received', 'In Review', 'Approved', 'Paid', 'Rejected'))
);


-- ============================================================
-- 8. Create table: payments
-- Stores scheduled and actual payment data.
-- ============================================================

CREATE TABLE payments (
    payment_id INT PRIMARY KEY,
    invoice_id INT NOT NULL,
    scheduled_payment_date DATE NOT NULL,
    actual_payment_date DATE,
    payment_amount DECIMAL(12, 2) NOT NULL,
    payment_status VARCHAR(20) NOT NULL,

    CONSTRAINT fk_payments_invoice
        FOREIGN KEY (invoice_id)
        REFERENCES invoices (invoice_id),

    CONSTRAINT chk_payments_amount
        CHECK (payment_amount >= 0),

    CONSTRAINT chk_payments_status
        CHECK (payment_status IN ('Open', 'Paid', 'Cancelled')),

    CONSTRAINT chk_payments_actual_date
        CHECK (
            actual_payment_date IS NULL
            OR actual_payment_date >= DATE_SUB(scheduled_payment_date, INTERVAL 90 DAY)
        )
);


-- ============================================================
-- 9. Create table: invoice_events
-- Stores event log data for process analysis.
-- Each invoice can have multiple process events.
-- ============================================================

CREATE TABLE invoice_events (
    event_id INT PRIMARY KEY,
    invoice_id INT NOT NULL,
    event_name VARCHAR(100) NOT NULL,
    event_timestamp DATETIME NOT NULL,
    department_id INT NOT NULL,
    event_status VARCHAR(20) NOT NULL,

    CONSTRAINT fk_invoice_events_invoice
        FOREIGN KEY (invoice_id)
        REFERENCES invoices (invoice_id),

    CONSTRAINT fk_invoice_events_department
        FOREIGN KEY (department_id)
        REFERENCES departments (department_id),

    CONSTRAINT chk_invoice_events_name
        CHECK (
            event_name IN (
                'Invoice Received',
                'Data Validation',
                'PO Matching',
                'Exception Raised',
                'Correction Requested',
                'Correction Received',
                'Approval',
                'Approval Rejected',
                'Rework',
                'Payment Scheduled',
                'Paid'
            )
        ),

    CONSTRAINT chk_invoice_events_status
        CHECK (event_status IN ('Completed', 'Pending', 'Rejected'))
);


-- ============================================================
-- 10. Create indexes
-- These indexes support common joins and analysis queries.
-- ============================================================

CREATE INDEX idx_purchase_orders_vendor_id
    ON purchase_orders (vendor_id);

CREATE INDEX idx_purchase_orders_department_id
    ON purchase_orders (department_id);

CREATE INDEX idx_invoices_vendor_id
    ON invoices (vendor_id);

CREATE INDEX idx_invoices_po_id
    ON invoices (po_id);

CREATE INDEX idx_invoices_department_id
    ON invoices (department_id);

CREATE INDEX idx_invoices_exception_type_id
    ON invoices (exception_type_id);

CREATE INDEX idx_payments_invoice_id
    ON payments (invoice_id);

CREATE INDEX idx_invoice_events_invoice_id
    ON invoice_events (invoice_id);

CREATE INDEX idx_invoice_events_department_id
    ON invoice_events (department_id);

CREATE INDEX idx_invoice_events_timestamp
    ON invoice_events (event_timestamp);