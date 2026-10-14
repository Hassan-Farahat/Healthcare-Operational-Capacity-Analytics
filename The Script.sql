--Database Schema Creation

-- Create the Healthcare Analytics Database
CREATE DATABASE HealthcareAnalytics;
GO

USE HealthcareAnalytics;
GO

-- Departments Dimension
CREATE TABLE Dim_Departments (
    department_id INT PRIMARY KEY,
    department_name VARCHAR(100),
    total_beds INT,
    daily_operational_cost DECIMAL(10,2)
);

-- Patients Dimension
CREATE TABLE Dim_Patients (
    patient_id INT PRIMARY KEY,
    patient_name VARCHAR(100),
    age INT,
    gender VARCHAR(10),
    insurance_provider VARCHAR(50)
);

-- Patient Admissions Fact Table
CREATE TABLE Fact_Admissions (
    admission_id INT PRIMARY KEY,
    patient_id INT FOREIGN KEY REFERENCES Dim_Patients(patient_id),
    department_id INT FOREIGN KEY REFERENCES Dim_Departments(department_id),
    admission_date DATE,
    discharge_date DATE,
    admission_type VARCHAR(20), -- 'Emergency', 'Elective'
    total_billed_amount DECIMAL(10,2),
    readmitted_30days BIT -- 1 = Yes, 0 = No
);


--Data Ingestion

-- Insert Departments
INSERT INTO Dim_Departments VALUES 
(1, 'Cardiology', 20, 1500.00),
(2, 'Orthopedics', 15, 1200.00),
(3, 'Emergency', 30, 2000.00),
(4, 'Neurology', 10, 1800.00);

-- Insert Patients
INSERT INTO Dim_Patients VALUES 
(101, 'John Doe', 65, 'Male', 'Medicare'),
(102, 'Jane Smith', 45, 'Female', 'BlueCross'),
(103, 'Robert Johnson', 72, 'Male', 'Medicare'),
(104, 'Emily Davis', 29, 'Female', 'Aetna'),
(105, 'Michael Brown', 58, 'Male', 'UnitedHealth');

-- Insert Patient Admissions Data
INSERT INTO Fact_Admissions VALUES 
(1001, 101, 1, '2026-08-01', '2026-08-10', 'Emergency', 18500.00, 1),
(1002, 102, 2, '2026-08-05', '2026-08-08', 'Elective', 8200.00, 0),
(1003, 103, 1, '2026-08-10', '2026-08-25', 'Emergency', 32000.00, 1),
(1004, 104, 3, '2026-08-12', '2026-08-13', 'Emergency', 3500.00, 0),
(1005, 105, 4, '2026-08-15', '2026-08-22', 'Emergency', 19400.00, 0),
(1006, 101, 1, '2026-09-01', '2026-09-07', 'Emergency', 14000.00, 0);



--Healthcare Operational & Financial Queries

-- ============================================================================
-- QUERY 1: Average Length of Stay (LOS) & Revenue per Bed-Day by Department
-- Business Goal: Measure resource utilization and daily billing efficiency per department.
-- ============================================================================

SELECT 
    d.department_name,
    d.total_beds,
    COUNT(a.admission_id) AS total_admissions,
    -- Calculate Average Length of Stay in Days
    AVG(DATEDIFF(day, a.admission_date, a.discharge_date)) AS avg_length_of_stay_days,
    SUM(a.total_billed_amount) AS gross_revenue,
    -- Calculate Billed Revenue per Occupied Day
    ROUND(SUM(a.total_billed_amount) / NULLIF(SUM(DATEDIFF(day, a.admission_date, a.discharge_date)), 0), 2) AS revenue_per_bed_day
FROM Fact_Admissions a
JOIN Dim_Departments d ON a.department_id = d.department_id
GROUP BY d.department_name, d.total_beds
ORDER BY gross_revenue DESC;


-- ============================================================================
-- QUERY 2: 30-Day Readmission Analysis by Insurance Provider
-- Business Goal: Identify risk profiles and readmission penalties by payer group.
-- ============================================================================

SELECT 
    p.insurance_provider,
    COUNT(a.admission_id) AS total_admissions,
    SUM(CAST(a.readmitted_30days AS INT)) AS total_readmissions,
    -- Calculate Readmission Rate %
    ROUND((SUM(CAST(a.readmitted_30days AS FLOAT)) / COUNT(a.admission_id)) * 100, 2) AS readmission_rate_pct
FROM Fact_Admissions a
JOIN Dim_Patients p ON a.patient_id = p.patient_id
GROUP BY p.insurance_provider
ORDER BY readmission_rate_pct DESC;


-- ============================================================================
-- QUERY 3: Departmental Profit Margin Analysis (Window Functions)
-- Business Goal: Calculate net profit after operational costs and rank department profitability.
-- ============================================================================

WITH Department_Financials AS (
    SELECT 
        d.department_id,
        d.department_name,
        SUM(a.total_billed_amount) AS total_revenue,
        -- Calculate Total Operational Cost = Daily Cost * Total Days Stayed
        SUM(DATEDIFF(day, a.admission_date, a.discharge_date) * d.daily_operational_cost) AS total_operational_cost
    FROM Dim_Departments d
    JOIN Fact_Admissions a ON d.department_id = a.department_id
    GROUP BY d.department_id, d.department_name
)
SELECT 
    department_id,
    department_name,
    total_revenue,
    total_operational_cost,
    (total_revenue - total_operational_cost) AS net_profit,
    ROUND(((total_revenue - total_operational_cost) / total_revenue) * 100, 2) AS profit_margin_pct,
    -- Rank departments by net profit contribution using window function
    DENSE_RANK() OVER (ORDER BY (total_revenue - total_operational_cost) DESC) AS profitability_rank
FROM Department_Financials
ORDER BY profitability_rank;