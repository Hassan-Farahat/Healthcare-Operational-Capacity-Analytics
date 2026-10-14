# Healthcare Operational Analytics & Capacity Management

## Executive Overview
This operational analytics project addresses key healthcare administration challenges: managing bed occupancy, controlling length of stay (LOS), monitoring 30-day readmission rates, and evaluating departmental financial margins. Built using SQL Server, it translates clinical admission records into strategic capacity-planning decisions.

## Data Model Architecture
The relational database models core clinical and operational dimensions:
- **Fact Table:** `Fact_Admissions`
- **Dimension Tables:** `Dim_Departments`, `Dim_Patients`

## Key Business Insights & Analytical Output

### 1. Capacity & Length of Stay (LOS)
- **Cardiology** exhibits the longest average length of stay, driving high bed occupancy and resource utilization.
- Revenue per bed-day metrics isolate throughput efficiency across clinical units.

### 2. 30-Day Readmission Risks
- Patients covered by **Medicare** show higher readmission rates, highlighting focus areas to mitigate healthcare penalty risks.

### 3. Departmental Profitability
- High operational overhead in emergency and specialized care units impacts net margins.
- Using window functions (`DENSE_RANK()`), departments are ranked by net profit after factoring in daily operational costs.

## Strategic Business Recommendations
1. **Discharge Planning Optimization:** Establish early discharge protocols for high-LOS departments to free up bed capacity.
2. **Readmission Reduction Programs:** Deploy targeted post-discharge follow-ups for high-risk payer groups to lower readmission rates.