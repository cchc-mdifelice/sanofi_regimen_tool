select count(distinct patientid) from PROD_CCHC.SANOFI.MM_FLRN_MM_LINEOFTHERAPY_0901;

-- Create Rough Regimen list 
Create or replace temporary table Line_zero_pats as
select patientid from PROD_CCHC.SANOFI.MM_FLRN_MM_LINEOFTHERAPY_0901 where LINENUMBER = 0;
create or replace temporary table Big_LoT_Table_1 as
select *,
CASE 
    WHEN LINENAME LIKE '%Carfilzomib%,%Cyclophosphamide%,%Dexamethasone%,%Thalidomide%' THEN 'KCTd'
    WHEN LINENAME LIKE '%Bortezomib%,%Daratumumab%,%Dexamethasone%,%Lenalidomide%' THEN 'DVRd'
    WHEN LINENAME LIKE '%Carfilzomib%,%Dexamethasone%,%Lenalidomide%,%Pomalidomide%' THEN 'KPRd'
    WHEN LINENAME LIKE '%Carfilzomib%,%Daratumumab%,%Dexamethasone%,%Lenalidomide%' THEN 'DKRd'
    WHEN LINENAME LIKE '%Bortezomib%,%Daratumumab%,%Melphalan%,%Prednisone%' THEN 'DVMp'
    WHEN LINENAME LIKE '%Bortezomib%,%Daratumumab%,%Dexamethasone%,%Thalidomide%' THEN 'DVTd'
    WHEN LINENAME LIKE '%Bortezomib%,%Dexamethasone%,%Pomalidomide%' THEN 'PVd'
    WHEN LINENAME LIKE '%Bortezomib%,%Daratumumab%,%Dexamethasone%' THEN 'DVd'
    WHEN LINENAME LIKE '%Bortezomib%,%Dexamethasone%,%Lenalidomide%' THEN 'VRd'
    WHEN LINENAME LIKE '%Daratumumab%,%Dexamethasone%,%Lenalidomide%' THEN 'DRd'
    WHEN LINENAME LIKE '%Bortezomib%,%Cyclophosphamide%,%Dexamethasone%' THEN 'VCd'
    WHEN LINENAME LIKE '%Dexamethasone%,%Ixazomib%,%Lenalidomide%' THEN 'IRd'
    WHEN LINENAME LIKE '%Daratumumab%,%Dexamethasone%,%Pomalidomide%' THEN 'DPd'
    WHEN LINENAME LIKE '%Carfilzomib%,%Dexamethasone%,%Lenalidomide%' THEN 'KRd'
    WHEN LINENAME LIKE '%Carfilzomib%,%examethasone%,%Pomalidomide%' THEN 'KPd'
    WHEN LINENAME LIKE '%Dexamethasone%,%Elotuzumab%,Pomalidomide%' THEN 'EPd'
    WHEN LINENAME LIKE '%Carfilzomib%,%Daratumumab%,%Dexamethasone%' THEN 'DKd'
    WHEN LINENAME LIKE '%Carfilzomib%,%Dexamethasone%,%Isatuximab-Irfc%' THEN 'IsaKd'
    WHEN LINENAME LIKE '%Bortezomib%,%Dexamethasone%,%Thalidomide%' THEN 'VTd'
    WHEN LINENAME LIKE '%Elotuzumab%,%Dexamethasone%,%Lenalidomide%' THEN 'ERd'
    WHEN LINENAME LIKE '%Dexamethasone%,%Isatuximab-Irfc%,%Pomalidomide%' THEN 'IsaPd'
    WHEN LINENAME LIKE '%Cyclophosphamide%,%Dexamethasone%,%Pomalidomide%' THEN 'PCd'
    WHEN LINENAME LIKE '%Cyclophosphamide%,%Dexamethasone%' THEN 'Cd'
    WHEN LINENAME LIKE '%Carfilzomib%,%Dexamethasone%' THEN 'Kd'
    WHEN LINENAME LIKE '%Dexamethasone%,%Lenalidomide%' THEN 'Rd'
    WHEN LINENAME LIKE '%Bortezomib%,%Dexamethasone%' THEN 'Vd'
    WHEN LINENAME LIKE '%Bortezomib%,%Lenalidomide' THEN 'VR'
    WHEN LINENAME LIKE '%Dexamethasone%,Pomalidomide%' THEN 'Pd'
    WHEN LINENAME LIKE '%Daratumumab%,%Dexamethasone%' THEN 'Dd'
    WHEN LINENAME LIKE '%Transplant%' THEN 'SCT'
    WHEN LINENAME LIKE '%Daratumumab%' THEN 'D Mono'
    WHEN LINENAME LIKE '%Ixazomib%' THEN 'Other Ixa'
    WHEN LINENAME LIKE '%Isatuximab-Irfc%' THEN 'Other Isa'
    WHEN LINENAME LIKE '%Ciltacabtagene Autoleucel%' THEN 'CAR-T'
    WHEN LINENAME LIKE 'Bortezomib' THEN 'V mono'
    WHEN LINENAME LIKE '%Selinexor%' THEN 'Selinexor'
    WHEN LINENAME LIKE 'Lenalidomide' THEN 'R mono'
    WHEN LINENAME LIKE 'Dexamethasone' THEN 'd mono'
    WHEN LINENAME LIKE 'Carfilzomib' THEN 'K mono'
    WHEN LINENAME LIKE 'Pomalidomide' THEN 'P mono'
    WHEN LINENAME LIKE '%Cyclophosphamide%' THEN 'C mono'
    WHEN LINENAME LIKE '%Clinical Study Drug%' THEN 'Clinical Study Drug'
    ELSE 'Other'
END AS Regimen
from prod_cchc.sanofi.mm_flrn_mm_lineoftherapy_0901;




-- Create a table of bundled line of therapy
-- This takes each line of therapy and bundles them into column
create or replace temporary table bundled_patient_line as
WITH CombinedTherapy AS (
    SELECT
        PATIENTID,
        LINENUMBER,
        ARRAY_TO_STRING(ARRAY_AGG(LINENAME) WITHIN GROUP (ORDER BY STARTDATE), ' -> ') as CombinedLine
    FROM
        prod_cchc.sanofi.mm_flrn_mm_lineoftherapy_0901
    GROUP BY
        PATIENTID, LINENUMBER
)

SELECT
    PATIENTID,
    LINENUMBER,
    CombinedLine
FROM
    CombinedTherapy
ORDER BY
    PATIENTID, LINENUMBER;
 
-- Join combined line 
create or replace temporary table big_lot_table_2 as
select a.*,b.CombinedLine
from Big_LoT_Table_1 a
left join bundled_patient_line b
on a.patientid = b.patientid
and a.linenumber = b.linenumber;

-- Create a flag for first treatment in Line Each 
create or replace temporary table big_lot_table_3 as
WITH FirstTreatment AS (
    SELECT
        PATIENTID,
        LINENUMBER,
        MIN(STARTDATE) AS FirstStartDate
    FROM
        big_lot_table_2
    GROUP BY
        PATIENTID,
        LINENUMBER
)

SELECT
    t.*,
    CASE
        WHEN t.STARTDATE = ft.FirstStartDate THEN 1
        ELSE 0
    END AS IsFirstTreatment
FROM
    big_lot_table_2 t
LEFT JOIN
    FirstTreatment ft
ON
    t.PATIENTID = ft.PATIENTID AND t.LINENUMBER = ft.LINENUMBER;




-- Create two tables of Patients with and without Transplant 
-- 12892 Patient Total in Big_LOT_LOT_3
select count(distinct patientid) 
from BIG_LOT_TABLE_3 ;

create or replace temporary table Line_zero_Lot as
select * from prod_cchc.sanofi.mm_flrn_mm_lineoftherapy_0901 where patientid in (select patientid from Line_zero_pats);
--Transplant Patients
create or replace temporary table transplant_lot_pats as
select patientid 
from BIG_LOT_TABLE_3
where LINENAME = 'Transplant';
-- No transplant patients
create or replace temporary table no_transplant_lot_pats as
select patientid 
from BIG_LOT_TABLE_3
where patientid not in (select patientid from transplant_lot_pats);

create or replace temporary table transplant_lot as
select * 
from BIG_LOT_TABLE_3
where PATIENTID in (select patientid from transplant_lot_pats);

create or replace temporary table no_transplant_lot as
select *
from BIG_LOT_TABLE_3
where PATIENTID in (select patientid from no_transplant_lot_pats);

--3547 Patient total
select count(distinct patientid) from transplant_lot_pats;
--9345 Patient total
select count(distinct patientid) from no_transplant_lot_pats;


--PROD_CCHC.SANOFI.MM_FLRN_MM_MULTIPLEMYELOMA_0901
--PROD_CCHC.SANOFI.MM_FLRN_MM_TRANSPLANT_0901
--PROD_CCHC.SANOFI.MM_FLRN_DEMOGRAPHICS_0901




------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------(2910 pats Line 0 --- 2810 Line 1)----------------------------------------------------------------------------------------------------------------------------------------------

create or replace temporary table line_zero_lot as
select * from prod_cchc.sanofi.mm_flrn_mm_lineoftherapy_0901 where patientid in (select patientid from line_zero_pats);

create or replace temporary table transplant_line_zero_lot as
select * 
from line_zero_lot 
where linename like '%Transplant%';

-- create two tables for transplant and no transplant Line 0 patients
create or replace temporary table no_transplant_line_zero_lot as
select *
FROM line_zero_lot
where patientid not in (select patientid from transplant_line_zero_lot);

create or replace temporary table transplant_line_zero_lot_main as 
select *
from prod_cchc.sanofi.mm_flrn_mm_lineoftherapy_0901
where patientid in (select patientid from transplant_line_zero_lot);


-- Counting the number of patients who started on Daratumumab or Isatuximab-Irfc by Line and by Year
select count(distinct patientid), year(startdate)
from no_transplant_lot
WHERE 
    linenumber = 1
AND isfirsttreatment = 1
AND 
    (linename LIKE '%Daratumumab%' OR linename LIKE '%Isatuximab-Irfc%')
group by year(startdate)
order by year(startdate) asc;

-- Use this to count the number of patients who started on Daratumumab or Isatuximab-Irfc by Line and by Year
WITH EarliestDates AS (
    SELECT
        PATIENTID,
        LINENUMBER,
        MIN(STARTDATE) AS EarliestStartDate,
        CASE 
            WHEN LINENUMBER >= 4 THEN '4+' 
            ELSE CAST(LINENUMBER AS VARCHAR)
        END AS LINEGROUP
    FROM
        no_transplant_lot
    WHERE
        LINENAME LIKE '%Daratumumab%' OR LINENAME LIKE '%Isatuximab-Irfc%'
    GROUP BY
        PATIENTID, LINENUMBER
)
SELECT
    EXTRACT(YEAR FROM EarliestStartDate) AS YEAR,
    LINEGROUP,
    COUNT(DISTINCT PATIENTID) AS PATIENT_COUNT
FROM
    EarliestDates
GROUP BY
    EXTRACT(YEAR FROM EarliestStartDate), LINEGROUP
ORDER BY
    YEAR, LINEGROUP;


--Identify earliest usage of Daratumumab or Isatuximab-Irfc
WITH EarliestDates AS (
    SELECT
        PATIENTID,
        LINENUMBER,
        MIN(STARTDATE) AS EarliestStartDate,
        CASE 
            WHEN LINENUMBER >= 4 THEN '4+' 
            ELSE CAST(LINENUMBER AS VARCHAR)
        END AS LINEGROUP
    FROM
        no_transplant_lot
    GROUP BY
        PATIENTID, LINENUMBER
)
SELECT
    EXTRACT(YEAR FROM EarliestStartDate) AS YEAR,
    LINEGROUP,
    COUNT(DISTINCT PATIENTID) AS PATIENT_COUNT
FROM
    EarliestDates
GROUP BY
    EXTRACT(YEAR FROM EarliestStartDate), LINEGROUP
ORDER BY
    YEAR, LINEGROUP;

-- Find the number of patients who started on Daratumumab or Isatuximab-Irfc
create or replace temporary table CD38_patients_1 as 
select min(startdate) as first_CD38_date,patientid
from big_lot_table_3
where combinedline like '%Daratumumab%' 
or combinedline like '%Isatuximab-Irfc%'
group by patientid; 


--create CD38 Exposure flag

CREATE OR REPLACE TEMPORARY TABLE cd38_patients_2 AS
WITH merged_data AS (
    SELECT 
        b.*,
        c.FIRST_CD38_DATE
    FROM 
        big_lot_table_3 b
    LEFT JOIN 
        cd38_patients_1 c
    ON 
        b.PATIENTID = c.PATIENTID
),

cd38_line AS (
    SELECT 
        m.PATIENTID,
        MIN(m.linenumber) AS CD38_LOT
    FROM
        merged_data m
    WHERE 
        m.STARTDATE <= m.FIRST_CD38_DATE
        AND (m.ENDDATE IS NULL OR m.ENDDATE >= m.FIRST_CD38_DATE)
    GROUP BY 
        m.PATIENTID
)

SELECT 
    m.*,
    CASE 
        WHEN m.linenumber > COALESCE(cl.CD38_LOT, 0) AND m.STARTDATE >= m.FIRST_CD38_DATE THEN 1
        ELSE 0
    END AS CD38_exposed_flag
FROM 
    merged_data m
LEFT JOIN
    cd38_line cl
ON
    m.PATIENTID = cl.PATIENTID
ORDER BY 
    m.PATIENTID, m.STARTDATE;

select patientid,linenumber,linename,first_cd38_date,startdate,enddate,cd38_exposed_flag
from cd38_patients_2
where patientid like 'F002651CEF65E';

--create transplant flag 
create or replace temporary table big_lot_table_4 as
select * ,
    CASE
        when patientid in (select patientid from transplant_lot_pats) then 1
        else 0
    end as transplant_flag
from cd38_patients_2;



------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Find treated patients from 2022-08-01 to 2023-07-31(2808 treated patients)(917 recieved first CD38 treatment in window)

create or replace temporary table small_patient_journey as
select * ,
 CASE 
    WHEN LINENUMBER >= 4 THEN '4+' 
    ELSE CAST(LINENUMBER AS VARCHAR)
END AS LINENUMBER_1
from big_lot_table_4
where startdate between '2022-08-01' and '2023-07-31';



--2022
--2988 total treated -- 
--line 1 1471
--line 1 darz 432
--line 2 871
--line 2 darz 435

select count(distinct patientid) 
from small_patient_journey
where linenumber = 1;
create or replace temporary table big_lot_table_5 as
select 
*,
 CASE 
    WHEN LINENUMBER >= 4 THEN '4+' 
    ELSE CAST(LINENUMBER AS VARCHAR)
END AS enhanced_linenumber
from big_lot_table_4;


select * from big_lot_table_5 limit 50;

select COUNT(distinct patientid) as pat_count,regimen
from big_lot_table_5
where year(startdate) >= 2015
and isfirsttreatment = 1
group by regimen;



--------------------------------------Create FLag for Len Exposure------------------------------------------------------
-- Find the number of patients who started on Lenodalimide
create or replace temporary table len_patients as 
select min(startdate) as first_len_date,patientid
from big_lot_table_5
where combinedline like '%Lenalidomide%'
group by patientid; 

select * from len_patients;



CREATE OR REPLACE TEMPORARY TABLE big_lot_table_6 AS
WITH merged_data AS (
    SELECT 
        b.*,
        c.FIRST_LEN_DATE
    FROM 
        big_lot_table_5 b
    LEFT JOIN 
        len_patients c
    ON 
        b.PATIENTID = c.PATIENTID
),

len_line AS (
    SELECT 
        m.PATIENTID,
        MIN(m.linenumber) AS len_LOT
    FROM
        merged_data m
    WHERE 
        m.STARTDATE <= m.FIRST_LEN_DATE
        AND (m.ENDDATE IS NULL OR m.ENDDATE >= m.FIRST_LEN_DATE)
    GROUP BY 
        m.PATIENTID
)

SELECT 
    m.*,
    CASE 
        WHEN m.linenumber > COALESCE(cl.LEN_LOT, 0) AND m.STARTDATE >= m.FIRST_LEN_DATE THEN 1
        ELSE 0
    END AS LEN_FLAG
FROM 
    merged_data m
LEFT JOIN
    LEN_line cl
ON
    m.PATIENTID = cl.PATIENTID
ORDER BY 
    m.PATIENTID, m.STARTDATE;


-- add Line 0 patients
create or replace temporary table big_lot_table_7 as
select *,
    CASE 
        when patientid in (select patientid from line_zero_pats) then 1
        else 0
    end as line_zero_flag
from big_lot_table_6;


-- Step 1: Modify len_maintenance to capture rows with LINENAME as LENALIDOMIDE
CREATE OR REPLACE TEMPORARY TABLE len_maintenance AS
SELECT PATIENTID, LINENUMBER
FROM big_lot_table_7
WHERE (UPPER(COMBINEDLINE) LIKE '%LENALIDOMIDE%'
       OR UPPER(LINENAME) = 'LENALIDOMIDE')
AND UPPER(ISMAINTENANCETHERAPY) = 'TRUE';

CREATE OR REPLACE TEMPORARY TABLE len_refractory_next_line AS
SELECT a.PATIENTID, a.LINENUMBER + 1 AS NEXT_LINENUMBER
FROM len_maintenance a
JOIN big_lot_table_7 b ON a.PATIENTID = b.PATIENTID 
WHERE a.LINENUMBER + 1 = b.LINENUMBER;

-- Step 2: Add Len Refractory flag column in big_lot_table_8
CREATE OR REPLACE TEMPORARY TABLE big_lot_table_8 AS
SELECT a.*, 
       CASE WHEN b.PATIENTID IS NOT NULL THEN 1 ELSE 0 END AS len_refractory_flag,
       CASE 
           WHEN a.combinedline LIKE '%Daratumumab%' THEN 1
           WHEN a.combinedline LIKE '%Isatuximab-Irfc%' THEN 1
           ELSE 0
       END AS cd38_flag,
       -- New flag for Len Refractory
       CASE 
           WHEN UPPER(a.LINENAME) = 'LENALIDOMIDE' THEN 1
           ELSE 0
       END AS len_refractory_by_name_flag
FROM big_lot_table_7 a
LEFT JOIN len_refractory_next_line b ON a.PATIENTID = b.PATIENTID AND a.LINENUMBER = b.NEXT_LINENUMBER;


-- 16 Patients began therapy in 2023(other 163 began in 2022 but had some other treatment in 2023-think SCT OR 
-- Maintentence)
--174 Patient Total L1 SCT (11 of which are on CD38)
--632 Patient Total L1 Non SCT
select * from big_lot_table_8 limit 50;

select distinct linename from big_lot_table_8 
where linename like '%Daratumumab%';
create or replace temporary table isa_new as 
select *,
    min(case when linename like '%Isatuximab-Irfc%' then startdate end) over (partition by patientid) as isa_first_treatment
from big_lot_table_8
where linename like '%Isatuximab-Irfc%';

select year(isa_first_treatment),count(distinct patientid) 
from isa_new
group by year(isa_first_treatment)
order by year(isa_first_treatment) asc;


-- Step 1: Extract year from STARTDATE
-- Step 1: Extract year from STARTDATE
-- Step 1: Extract year from STARTDATE
WITH YearData AS (
    SELECT *,
           year(STARTDATE) AS YEAR
    FROM big_lot_table_8
    where line_zero_flag = 0
    and year(startdate) >= 2015
    and cd38_exposed_flag = 0
    -- and cd38_flag = 1
    and isfirsttreatment = 1
),


-- Step 2: Classify LINENUMBER
ClassifiedData AS (
    SELECT *,
           CASE
               WHEN LINENUMBER = 1 THEN 'L1'
               WHEN LINENUMBER = 2 THEN 'L2'
               WHEN LINENUMBER = 3 THEN 'L3'
               ELSE 'L4+'
           END AS LINE_CLASS
    FROM YearData
),

-- Step 3: Group and count distinct PATIENTID
GroupedData AS (
    SELECT YEAR, LINE_CLASS, TRANSPLANT_FLAG, COUNT(DISTINCT PATIENTID) AS DISTINCT_PATIENT_COUNT
    FROM ClassifiedData
    GROUP BY YEAR, LINE_CLASS, TRANSPLANT_FLAG
)

-- Step 4: Pivot the table
SELECT YEAR,
    MAX(CASE WHEN LINE_CLASS = 'L1' AND TRANSPLANT_FLAG = 1 THEN DISTINCT_PATIENT_COUNT ELSE NULL END) AS "L1_Transplant",
       MAX(CASE WHEN LINE_CLASS = 'L1' AND TRANSPLANT_FLAG = 0 THEN DISTINCT_PATIENT_COUNT ELSE NULL END) AS "L1_No_Trans",
       MAX(CASE WHEN LINE_CLASS = 'L2' AND TRANSPLANT_FLAG = 1 THEN DISTINCT_PATIENT_COUNT ELSE NULL END) AS "L2_Transplant",
       MAX(CASE WHEN LINE_CLASS = 'L2' AND TRANSPLANT_FLAG = 0 THEN DISTINCT_PATIENT_COUNT ELSE NULL END) AS "L2_No_Trans",
       MAX(CASE WHEN LINE_CLASS = 'L3' AND TRANSPLANT_FLAG = 1 THEN DISTINCT_PATIENT_COUNT ELSE NULL END) AS "L3_Transplant",
       MAX(CASE WHEN LINE_CLASS = 'L3' AND TRANSPLANT_FLAG = 0 THEN DISTINCT_PATIENT_COUNT ELSE NULL END) AS "L3_No_Trans",
       MAX(CASE WHEN LINE_CLASS = 'L4+' AND TRANSPLANT_FLAG = 1 THEN DISTINCT_PATIENT_COUNT ELSE NULL END) AS "L4+_Transplant",
       MAX(CASE WHEN LINE_CLASS = 'L4+' AND TRANSPLANT_FLAG = 0 THEN DISTINCT_PATIENT_COUNT ELSE NULL END) AS "L4+_No_Trans"
       
FROM GroupedData
GROUP BY YEAR
ORDER BY YEAR;

WITH YearlyCounts AS (
    SELECT 
        enhanced_linenumber, 
        EXTRACT(YEAR FROM STARTDATE) AS TreatmentYear,
        COUNT(DISTINCT PATIENTID) AS pat_count
    FROM big_lot_table_8
    WHERE line_zero_flag = 0
    and EXTRACT(YEAR FROM STARTDATE) >= 2015
    and isfirsttreatment = 1
    and cd38_flag = 1
    GROUP BY enhanced_linenumber, EXTRACT(YEAR FROM STARTDATE)
)

SELECT 
    enhanced_linenumber,
    COALESCE(SUM(CASE WHEN TreatmentYear = 2015 THEN pat_count ELSE 0 END), 0) AS "2015",
    COALESCE(SUM(CASE WHEN TreatmentYear = 2016 THEN pat_count ELSE 0 END), 0) AS "2016",
    COALESCE(SUM(CASE WHEN TreatmentYear = 2017 THEN pat_count ELSE 0 END), 0) AS "2017",
    COALESCE(SUM(CASE WHEN TreatmentYear = 2018 THEN pat_count ELSE 0 END), 0) AS "2018",
    COALESCE(SUM(CASE WHEN TreatmentYear = 2019 THEN pat_count ELSE 0 END), 0) AS "2019",
    COALESCE(SUM(CASE WHEN TreatmentYear = 2020 THEN pat_count ELSE 0 END), 0) AS "2020",
    COALESCE(SUM(CASE WHEN TreatmentYear = 2021 THEN pat_count ELSE 0 END), 0) AS "2021",
    COALESCE(SUM(CASE WHEN TreatmentYear = 2022 THEN pat_count ELSE 0 END), 0) AS "2022",
    COALESCE(SUM(CASE WHEN TreatmentYear = 2023 THEN pat_count ELSE 0 END), 0) AS "2023"
FROM YearlyCounts
GROUP BY enhanced_linenumber
ORDER BY enhanced_linenumber;

WITH MinYearlyTreatment AS (
    SELECT 
        PATIENTID,
        EXTRACT(YEAR FROM MIN(STARTDATE)) AS TreatmentYear,
        MIN(STARTDATE) AS MinStartDate
    FROM big_lot_table_8
    WHERE line_zero_flag = 0
    AND EXTRACT(YEAR FROM STARTDATE) >= 2015
    and cd38_flag = 1
    and isfirsttreatment = 1
    GROUP BY PATIENTID, EXTRACT(YEAR FROM STARTDATE)
),
YearlyCounts AS (
    SELECT 
        b.linenumber, 
        MYT.TreatmentYear,
        COUNT(DISTINCT MYT.PATIENTID) AS pat_count
    FROM big_lot_table_8 b
    JOIN MinYearlyTreatment MYT ON b.PATIENTID = MYT.PATIENTID AND b.STARTDATE = MYT.MinStartDate
    GROUP BY b.linenumber, MYT.TreatmentYear
)
SELECT 
    linenumber,
    COALESCE(SUM(CASE WHEN TreatmentYear = 2015 THEN pat_count ELSE 0 END), 0) AS "2015",
    COALESCE(SUM(CASE WHEN TreatmentYear = 2016 THEN pat_count ELSE 0 END), 0) AS "2016",
    COALESCE(SUM(CASE WHEN TreatmentYear = 2017 THEN pat_count ELSE 0 END), 0) AS "2017",
    COALESCE(SUM(CASE WHEN TreatmentYear = 2018 THEN pat_count ELSE 0 END), 0) AS "2018",
    COALESCE(SUM(CASE WHEN TreatmentYear = 2019 THEN pat_count ELSE 0 END), 0) AS "2019",
    COALESCE(SUM(CASE WHEN TreatmentYear = 2020 THEN pat_count ELSE 0 END), 0) AS "2020",
    COALESCE(SUM(CASE WHEN TreatmentYear = 2021 THEN pat_count ELSE 0 END), 0) AS "2021",
    COALESCE(SUM(CASE WHEN TreatmentYear = 2022 THEN pat_count ELSE 0 END), 0) AS "2022",
    COALESCE(SUM(CASE WHEN TreatmentYear = 2023 THEN pat_count ELSE 0 END), 0) AS "2023"
FROM YearlyCounts
GROUP BY linenumber
ORDER BY linenumber asc;


-------------------------------TIME TO TREATMENT TABLES-----------------------------------------------------------
-- this has been solved skip this part

create or replace temporary table time_to_treatment_1 as
select a.*,b.diagnosisdate
from big_lot_table_8 a
left join PROD_CCHC.SANOFI.MM_FLRN_MM_MULTIPLEMYELOMA_0901 b
on a.patientid = b.patientid;



CREATE OR REPLACE TEMPORARY TABLE time_to_treatment_2 AS
WITH FirstTreatmentDates AS (
    SELECT
        PATIENTID,
        DIAGNOSISDATE,
        (MAX(CASE WHEN LINENUMBER = 1 THEN STARTDATE END)) AS Line1_StartDate,
        (MAX(CASE WHEN LINENUMBER = 2 THEN STARTDATE END)) AS Line2_StartDate,
        (MAX(CASE WHEN LINENUMBER = 3 THEN STARTDATE END)) AS Line3_StartDate,
        (MAX(CASE WHEN LINENUMBER = 4 THEN STARTDATE END)) AS Line4Plus_StartDate
    FROM time_to_treatment_1
    WHERE isfirsttreatment = 1
    GROUP BY PATIENTID, DIAGNOSISDATE
)

SELECT
    t.*,
    COALESCE(DATEDIFF(DAY, NULLIF(REPLACE(t.DIAGNOSISDATE, '\\N', ''), ''), f.Line1_StartDate), -10000000000) AS Line1_DaysToTreatment,
    COALESCE(DATEDIFF(DAY, NULLIF(REPLACE(t.DIAGNOSISDATE, '\\N', ''), ''), f.Line2_StartDate), -100000000000000) AS Line2_DaysToTreatment,
    COALESCE(DATEDIFF(DAY, NULLIF(REPLACE(t.DIAGNOSISDATE, '\\N', ''), ''), f.Line3_StartDate), -1000000000000) AS Line3_DaysToTreatment,
    COALESCE(DATEDIFF(DAY, NULLIF(REPLACE(t.DIAGNOSISDATE, '\\N', ''), ''), f.Line4Plus_StartDate), -1000000000000) AS Line4Plus_DaysToTreatment
FROM time_to_treatment_1 t
JOIN FirstTreatmentDates f ON t.PATIENTID = f.PATIENTID;




SELECT
    AVG(Line1_DaysToTreatment) AS Avg_Line1_DaysToTreatment,
    AVG(Line2_DaysToTreatment) AS Avg_Line2_DaysToTreatment,
    AVG(Line3_DaysToTreatment) AS Avg_Line3_DaysToTreatment,
    AVG(Line4Plus_DaysToTreatment) AS Avg_Line4Plus_DaysToTreatment
FROM time_to_treatment_2
where transplant_flag = 0
and line_zero_flag = 0;

-- drug counts by patient 

select drugname,count(distinct patientid) as pat_count
from prod_cchc.sanofi.mm_flrn_drugepisode_0901
where upper(drugname) in ('BORTEZOMIB' , 'LENALIDOMIDE' , 'DEXAMETHASONE' , 'DARATUMUMAB/HYALURONIDASE-FIHJ' ,'DARATUMUMAB',  'CYCLOPHOSPHAMIDE' , 'CARFILZOMIB' , 'POMALIDOMIDE' , 'TRANPLANT PROCEDURE' , 'IXAZOMIB' , 'MELPHALAN' , 'ELOTUZUMAB' , 'TRANSPLANT PREP' , 
'THALIDOMIDE' , 'DOXORUBICIN' , 'ISATUXIMAB-IRFC' , 'ETOPOSIDE' , 'CAR-T' , 'BENDAMUSTINE' , 'SELINEXOR' , 'BELANTAMAB MAFODOTIN-BLMF' , 'PREDNISONE' , 'CISPLATIN' , 'PANOBINOSTAT' , 'TECLISTAMAB-CQYV' ,
'DOXORUBICIN HCL LIPOSOMAL' , 'VINCRISTINE' , 'MELPHALAN FLUFENAMIDE HCL' , 'CILTACABTAGENE AUTOLEUCEL' , 'IDECABTAGENE VICLEUCEL' , 'TRANSPLANT' )
and year(linestartdate) >= 2018
and patientid not in (select patientid from line_zero_pats)
and patientid in (
                        select patientid from big_lot_table_8
                        where isfirsttreatment = 1
                        and year(startdate) >= 2018
                        )
group by drugname
order by pat_count desc;



-- Create a temporary table with the count of selected drugs for each patient
WITH DrugCounts AS (
    SELECT PatientID, COUNT(DISTINCT DrugName) AS DrugCount
    FROM prod_cchc.sanofi.mm_flrn_drugepisode_0901
    WHERE UPPER(DrugName) IN (
        'BORTEZOMIB', 'LENALIDOMIDE', 'DEXAMETHASONE', '%DARATUMUMAB%',
        'DARATUMUMAB/HYALURONIDASE-FIHJ', 'CYCLOPHOSPHAMIDE', 'CARFILZOMIB',
        'POMALIDOMIDE', 'TRANPLANT PROCEDURE', 'IXAZOMIB', 'MELPHALAN',
        'ELOTUZUMAB', 'TRANSPLANT PREP', 'THALIDOMIDE', 'DOXORUBICIN',
        'ISATUXIMAB-IRFC', 'ETOPOSIDE', 'CAR-T', 'BENDAMUSTINE', 'SELINEXOR',
        'BELANTAMAB MAFODOTIN-BLMF', 'PREDNISONE', 'CISPLATIN', 'PANOBINOSTAT',
        'TECLISTAMAB-CQYV', 'DOXORUBICIN HCL LIPOSOMAL', 'VINCRISTINE',
        'MELPHALAN FLUFENAMIDE HCL', 'CILTACABTAGENE AUTOLEUCEL',
        'IDECABTAGENE VICLEUCEL', 'TRANSPLANT'
    ) 
    and year(linestartdate) >= 2018
    and patientid not in (select patientid from line_zero_pats)
    and patientid in (
                        select patientid from big_lot_table_8
                        where isfirsttreatment = 1
                        and year(startdate) >= 2018
                        )
    GROUP BY PatientID
)

-- Count the number of patients for each unique drug count
SELECT DrugCount AS "Number of Drugs", COUNT(PatientID) AS "Number of Patients"
FROM DrugCounts
GROUP BY DrugCount
ORDER BY DrugCount;



WITH cd38_treatment AS (
    SELECT 
        COUNT(*) AS treatment_count,
        YEAR(startdate)*100 + quarter(startdate) AS quarter,
        enhanced_linenumber
    FROM 
        big_lot_table_8
    WHERE 
        line_zero_flag = 0
        AND cd38_flag = 1
        and transplant_flag = 0
    GROUP BY 
        YEAR(startdate)*100 + quarter(startdate),
        enhanced_linenumber
)

SELECT 
    COUNT(*) AS total_treatment_count,
    YEAR(a.startdate)*100 + quarter(a.startdate) AS quarter,
    a.enhanced_linenumber,
    COALESCE(b.treatment_count, 0) AS treatment_count
FROM 
    big_lot_table_8 a
LEFT JOIN 
    cd38_treatment b
    ON YEAR(a.startdate)*100 + quarter(a.startdate) = b.quarter
    AND a.enhanced_linenumber = b.enhanced_linenumber
WHERE 
    a.line_zero_flag = 0
    and a.transplant_flag = 0
GROUP BY 
    YEAR(a.startdate)*100 + quarter(a.startdate),
    a.enhanced_linenumber,
    b.treatment_count
ORDER BY 
    quarter,
    a.enhanced_linenumber ASC;


-------------------------------------------------------- CD38 Patient Profiling----------------------------------------------------------------

-- Extract diagnosis details for CD38 exposed patients
create or replace temporary table cd38_exposed_all_dx as
SELECT d.*
FROM PROD_CCHC.SANOFI.MM_FLRN_DIAGNOSIS_0901 d
JOIN (
    SELECT DISTINCT PATIENTID
    FROM big_lot_table_8
    WHERE cd38_exposed_flag = 1
    and line_zero_flag = 0
    and startdate >= '2018-05-01'
) exposed
ON d.PatientID = exposed.PATIENTID;

-- Extract diagnosis details for CD38 naive patients
create or replace temporary table cd38_naive_all_dx as
SELECT d.*
FROM PROD_CCHC.SANOFI.MM_FLRN_DIAGNOSIS_0901 d
JOIN (
    SELECT DISTINCT PATIENTID
    FROM big_lot_table_8
    WHERE cd38_exposed_flag = 0
    and startdate >= '2018-05-01'
    and line_zero_flag = 0
    and patientid not in (select patientid from big_lot_table_8 where cd38_exposed_flag = 1)
) naive
ON d.PatientID = naive.PATIENTID;


-- Extract demographic details for CD38 exposed patients(1766 patients)
create or replace temporary table cd38_exposed_all_demographics as
SELECT d.*
FROM PROD_CCHC.SANOFI.MM_FLRN_DEMOGRAPHICS_0901 d
JOIN (
    SELECT DISTINCT PATIENTID
    FROM big_lot_table_8
    WHERE cd38_exposed_flag = 1
    and line_zero_flag = 0
    and startdate >= '2018-05-01'
) exposed
ON d.PatientID = exposed.PATIENTID;

-- Extract demographic details for CD38 naive patients(6852)
create or replace temporary table cd38_naive_all_demographics as
SELECT d.*
FROM PROD_CCHC.SANOFI.MM_FLRN_DEMOGRAPHICS_0901 d
JOIN (
    SELECT DISTINCT PATIENTID
    FROM big_lot_table_8
    WHERE cd38_exposed_flag = 0
    and line_zero_flag = 0
    and startdate >= '2018-05-01'
    and patientid not in (select patientid from big_lot_table_8 where cd38_exposed_flag = 1)
) naive
ON d.PatientID = naive.PATIENTID;



---------------------------------------------------------Line 1 Code ----------------------------------------------------------------
---------------------------------------------------------TOTAL PATIENTS----------------------------------------------------------------
WITH LineProgressionPatients AS (
    SELECT 
        PATIENTID, 
        CD38_FLAG,
        YEAR(STARTDATE) AS TreatmentYear
    FROM 
        big_lot_table_8
    WHERE 
        LINENUMBER = 1
        AND LINE_ZERO_FLAG = 0
        AND EXTRACT(YEAR FROM STARTDATE) >= 2016
        AND ISFIRSTTREATMENT = 1
)

SELECT 
    TreatmentYear,
    COUNT(DISTINCT CASE WHEN CD38_FLAG = 1 THEN PATIENTID END) AS CD38_Patients,
    COUNT(DISTINCT CASE WHEN CD38_FLAG = 0 THEN PATIENTID END) AS Non_CD38_Patients
FROM 
    LineProgressionPatients
GROUP BY 
    TreatmentYear
ORDER BY 
    TreatmentYear;


--------------------------------------------------------------------------CD38 PATIENTS--------------------------------------------------------------

WITH RECURSIVE Calendar AS (
    SELECT 2016 AS TreatmentYear -- Start from 2016
    UNION ALL
    SELECT TreatmentYear + 1
    FROM Calendar
    WHERE TreatmentYear < 2023 -- Stop at 2023
),

Line_Progression_CD38_Patients AS (
    SELECT 
        PATIENTID,
        EXTRACT(YEAR FROM STARTDATE) AS TreatmentYear
    FROM 
        big_lot_table_8
    WHERE 
        LINENUMBER = 1
        AND LINE_ZERO_FLAG = 0
        AND CD38_FLAG = 1
        AND ISFIRSTTREATMENT = 1
        AND EXTRACT(YEAR FROM STARTDATE) >= 2016
),

NextLineFor_CD38_Patients AS (
    SELECT 
        l1.TreatmentYear,
        t.PATIENTID,
        t.CD38_FLAG AS NextLine_CD38_FLAG
    FROM 
        big_lot_table_8 t
    JOIN 
        Line_Progression_CD38_Patients l1 ON t.PATIENTID = l1.PATIENTID
    WHERE 
        t.LINENUMBER = 2
),

Line_Progression_CD38_Patients_Time AS (
    SELECT 
        PATIENTID,
        EXTRACT(YEAR FROM STARTDATE) AS TreatmentYear,
        STARTDATE AS FirstLineStartDate
    FROM 
        big_lot_table_8
    WHERE 
        LINENUMBER = 1
        AND LINE_ZERO_FLAG = 0
        AND CD38_FLAG = 1
        AND ISFIRSTTREATMENT = 1
        AND EXTRACT(YEAR FROM STARTDATE) >= 2016
),

NextLineFor_CD38_Patients_Time AS (
    SELECT 
        l2.TreatmentYear,
        t.PATIENTID,
        t.CD38_FLAG AS NextLine_CD38_FLAG,
        MONTHS_BETWEEN(t.STARTDATE, l2.FirstLineStartDate) AS MonthsToNextLine
    FROM 
        big_lot_table_8 t
    JOIN 
        Line_Progression_CD38_Patients_Time l2 ON t.PATIENTID = l2.PATIENTID
    WHERE 
        t.LINENUMBER = 2
)

SELECT 
    c.TreatmentYear,
    COUNT(DISTINCT CASE WHEN n.NextLine_CD38_FLAG = 1 THEN n.PATIENTID END) AS To_CD38,
    COUNT(DISTINCT CASE WHEN n.NextLine_CD38_FLAG = 0 THEN n.PATIENTID END) AS To_Non_CD38,
    AVG(CASE WHEN nt.NextLine_CD38_FLAG = 1 THEN nt.MonthsToNextLine END) AS AvgMonths_To_CD38,
    AVG(CASE WHEN nt.NextLine_CD38_FLAG = 0 THEN nt.MonthsToNextLine END) AS AvgMonths_To_Non_CD38
FROM 
    Calendar c
LEFT JOIN 
    NextLineFor_CD38_Patients n ON c.TreatmentYear = n.TreatmentYear
LEFT JOIN 
    NextLineFor_CD38_Patients_Time nt ON c.TreatmentYear = nt.TreatmentYear
GROUP BY 
    c.TreatmentYear
ORDER BY 
    c.TreatmentYear;


--------------------------------------------------------------------------NON CD38 PATIENTS--------------------------------------------------------------
WITH RECURSIVE Calendar AS (
    SELECT 2016 AS TreatmentYear -- Start from 2016
    UNION ALL
    SELECT TreatmentYear + 1
    FROM Calendar
    WHERE TreatmentYear < 2023 -- Stop at 2023
),

Line_Progression_Non_CD38_Patients AS (
    SELECT 
        PATIENTID,
        EXTRACT(YEAR FROM STARTDATE) AS TreatmentYear
    FROM 
        big_lot_table_8
    WHERE 
        LINENUMBER = 1
        AND LINE_ZERO_FLAG = 0
        AND CD38_FLAG = 0
        AND ISFIRSTTREATMENT = 1
        AND EXTRACT(YEAR FROM STARTDATE) >= 2016
),

NextLineFor_Non_CD38_Patients AS (
    SELECT 
        l1.TreatmentYear,
        t.PATIENTID,
        t.CD38_FLAG AS NextLine_CD38_FLAG
    FROM 
        big_lot_table_8 t
    JOIN 
        Line_Progression_Non_CD38_Patients l1 ON t.PATIENTID = l1.PATIENTID
    WHERE 
        t.LINENUMBER = 2
),

Line_Progression_CD38_Patients_Time AS (
    SELECT 
        PATIENTID,
        EXTRACT(YEAR FROM STARTDATE) AS TreatmentYear,
        STARTDATE AS FirstLineStartDate
    FROM 
        big_lot_table_8
    WHERE 
        LINENUMBER = 1
        AND LINE_ZERO_FLAG = 0
        AND CD38_FLAG = 0
        AND ISFIRSTTREATMENT = 1
        AND EXTRACT(YEAR FROM STARTDATE) >= 2016
),

NextLineFor_CD38_Patients_Time AS (
    SELECT 
        l2.TreatmentYear,
        t.PATIENTID,
        t.CD38_FLAG AS NextLine_CD38_FLAG,
        MONTHS_BETWEEN(t.STARTDATE, l2.FirstLineStartDate) AS MonthsToNextLine
    FROM 
        big_lot_table_8 t
    JOIN 
        Line_Progression_CD38_Patients_Time l2 ON t.PATIENTID = l2.PATIENTID
    WHERE 
        t.LINENUMBER = 2
)

SELECT 
    c.TreatmentYear,
    COUNT(DISTINCT CASE WHEN n.NextLine_CD38_FLAG = 1 THEN n.PATIENTID END) AS To_CD38,
    COUNT(DISTINCT CASE WHEN n.NextLine_CD38_FLAG = 0 THEN n.PATIENTID END) AS Remain_Non_CD38,
    AVG(CASE WHEN nt.NextLine_CD38_FLAG = 1 THEN nt.MonthsToNextLine END) AS AvgMonths_To_CD38,
    AVG(CASE WHEN nt.NextLine_CD38_FLAG = 0 THEN nt.MonthsToNextLine END) AS AvgMonths_To_Non_CD38
FROM 
    Calendar c
LEFT JOIN 
    NextLineFor_Non_CD38_Patients n ON c.TreatmentYear = n.TreatmentYear
LEFT JOIN 
    NextLineFor_CD38_Patients_Time nt ON c.TreatmentYear = nt.TreatmentYear
GROUP BY 
    c.TreatmentYear
ORDER BY 
    c.TreatmentYear;

----------------------------------------------------2nd Line Plus --------------------------------------------------------------------
---------------------------------------------------------TOTAL PATIENTS----------------------------------------------------------------

WITH RECURSIVE Calendar AS (
    SELECT 2016 AS TreatmentYear -- Start from 2016
    UNION ALL
    SELECT TreatmentYear + 1
    FROM Calendar
    WHERE TreatmentYear < 2023 -- Stop at 2023
),

LineProgressionPatients AS (
    SELECT 
        PATIENTID, 
        CD38_FLAG,
        EXTRACT(YEAR FROM STARTDATE) AS TreatmentYear
    FROM 
        big_lot_table_8
    WHERE 
        LINENUMBER = 2
        AND LINE_ZERO_FLAG = 0
        AND EXTRACT(YEAR FROM STARTDATE) >= 2016
        AND ISFIRSTTREATMENT = 1
        AND CD38_EXPOSED_FLAG = 0
)

SELECT 
    c.TreatmentYear,
    COUNT(DISTINCT CASE WHEN l.CD38_FLAG = 1 THEN l.PATIENTID END) AS CD38_Patients,
    COUNT(DISTINCT CASE WHEN l.CD38_FLAG = 0 THEN l.PATIENTID END) AS Non_CD38_Patients
FROM 
    Calendar c
LEFT JOIN 
    LineProgressionPatients l ON c.TreatmentYear = l.TreatmentYear
GROUP BY 
    c.TreatmentYear
ORDER BY 
    c.TreatmentYear;



--------------------------------------------------------------------------2L+ CD38 PATIENTS --------------------------------------------------------------

WITH RECURSIVE Calendar AS (
    SELECT 2016 AS TreatmentYear -- Start from 2016
    UNION ALL
    SELECT TreatmentYear + 1
    FROM Calendar
    WHERE TreatmentYear < 2023 -- Stop at 2023
),

Line_Progression_Non_CD38_Patients AS (
    SELECT 
        PATIENTID,
        EXTRACT(YEAR FROM STARTDATE) AS TreatmentYear
    FROM 
        big_lot_table_8
    WHERE 
        LINENUMBER = 2
        AND LINE_ZERO_FLAG = 0
        AND CD38_FLAG = 1
        AND ISFIRSTTREATMENT = 1
        AND EXTRACT(YEAR FROM STARTDATE) >= 2016
),

NextLineFor_Non_CD38_Patients AS (
    SELECT 
        l1.TreatmentYear,
        t.PATIENTID,
        t.CD38_FLAG AS NextLine_CD38_FLAG
    FROM 
        big_lot_table_8 t
    JOIN 
        Line_progression_Non_CD38_Patients l1 ON t.PATIENTID = l1.PATIENTID
    WHERE 
        t.LINENUMBER = 3
),

Line_Progression_CD38_Patients_Time AS (
    SELECT 
        PATIENTID,
        EXTRACT(YEAR FROM STARTDATE) AS TreatmentYear,
        STARTDATE AS SecondLineStartDate
    FROM 
        big_lot_table_8
    WHERE 
        LINENUMBER = 2
        AND LINE_ZERO_FLAG = 0
        AND CD38_FLAG = 1
        AND ISFIRSTTREATMENT = 1
        AND CD38_EXPOSED_FLAG = 0
        AND EXTRACT(YEAR FROM STARTDATE) >= 2016
),

NextLineFor_CD38_Patients_Time AS (
    SELECT 
        l2.TreatmentYear,
        t.PATIENTID,
        t.CD38_FLAG AS NextLine_CD38_FLAG,
        MONTHS_BETWEEN(t.STARTDATE, l2.SecondLineStartDate) AS MonthsToNextLine
    FROM 
        big_lot_table_8 t
    JOIN 
        Line_Progression_CD38_Patients_Time l2 ON t.PATIENTID = l2.PATIENTID
    WHERE 
        t.LINENUMBER = 3
)

SELECT 
    c.TreatmentYear,
    COUNT(DISTINCT CASE WHEN n.NextLine_CD38_FLAG = 1 THEN n.PATIENTID END) AS To_CD38,
    COUNT(DISTINCT CASE WHEN n.NextLine_CD38_FLAG = 0 THEN n.PATIENTID END) AS Remain_Non_CD38,
    AVG(CASE WHEN nt.NextLine_CD38_FLAG = 1 THEN nt.MonthsToNextLine END) AS AvgMonths_To_CD38,
    AVG(CASE WHEN nt.NextLine_CD38_FLAG = 0 THEN nt.MonthsToNextLine END) AS AvgMonths_To_Non_CD38
FROM 
    Calendar c
LEFT JOIN 
    NextLineFor_Non_CD38_Patients n ON c.TreatmentYear = n.TreatmentYear
LEFT JOIN 
    NextLineFor_CD38_Patients_Time nt ON c.TreatmentYear = nt.TreatmentYear
GROUP BY 
    c.TreatmentYear
ORDER BY 
    c.TreatmentYear;


--------------------------------------------------------------------------2L+ NON CD38 PATIENTS --------------------------------------------------------------


--------------------------------------------------------------------


------------------------------Line 2 PLUS NON CD-------------------------------------------------------
WITH RECURSIVE Calendar AS (
    SELECT 2016 AS TreatmentYear -- Start from 2016
    UNION ALL
    SELECT TreatmentYear + 1
    FROM Calendar
    WHERE TreatmentYear < 2023 -- Stop at 2023
),

Line_Progression_Non_CD38_Patients AS (
    SELECT 
        PATIENTID,
        EXTRACT(YEAR FROM STARTDATE) AS TreatmentYear
    FROM 
        big_lot_table_8
    WHERE 
        LINENUMBER = 2
        AND LINE_ZERO_FLAG = 0
        AND CD38_FLAG = 0
        AND ISFIRSTTREATMENT = 1
        AND EXTRACT(YEAR FROM STARTDATE) >= 2016
),

NextLineFor_Non_CD38_Patients AS (
    SELECT 
        l1.TreatmentYear,
        t.PATIENTID,
        t.CD38_FLAG AS NextLine_CD38_FLAG
    FROM 
        big_lot_table_8 t
    JOIN 
        Line_progression_Non_CD38_Patients l1 ON t.PATIENTID = l1.PATIENTID
    WHERE 
        t.LINENUMBER = 3
),

Line_Progression_CD38_Patients_Time AS (
    SELECT 
        PATIENTID,
        EXTRACT(YEAR FROM STARTDATE) AS TreatmentYear,
        STARTDATE AS SecondLineStartDate
    FROM 
        big_lot_table_8
    WHERE 
        LINENUMBER = 2
        AND LINE_ZERO_FLAG = 0
        AND CD38_FLAG = 0
        AND ISFIRSTTREATMENT = 1
        AND CD38_EXPOSED_FLAG = 0
        AND EXTRACT(YEAR FROM STARTDATE) >= 2016
),

NextLineFor_CD38_Patients_Time AS (
    SELECT 
        l2.TreatmentYear,
        t.PATIENTID,
        t.CD38_FLAG AS NextLine_CD38_FLAG,
        MONTHS_BETWEEN(t.STARTDATE, l2.SecondLineStartDate) AS MonthsToNextLine
    FROM 
        big_lot_table_8 t
    JOIN 
        Line_Progression_CD38_Patients_Time l2 ON t.PATIENTID = l2.PATIENTID
    WHERE 
        t.LINENUMBER = 3
)

SELECT 
    c.TreatmentYear,
    COUNT(DISTINCT CASE WHEN n.NextLine_CD38_FLAG = 1 THEN n.PATIENTID END) AS To_CD38,
    COUNT(DISTINCT CASE WHEN n.NextLine_CD38_FLAG = 0 THEN n.PATIENTID END) AS Remain_Non_CD38,
    AVG(CASE WHEN nt.NextLine_CD38_FLAG = 1 THEN nt.MonthsToNextLine END) AS AvgMonths_To_CD38,
    AVG(CASE WHEN nt.NextLine_CD38_FLAG = 0 THEN nt.MonthsToNextLine END) AS AvgMonths_To_Non_CD38
FROM 
    Calendar c
LEFT JOIN 
    NextLineFor_Non_CD38_Patients n ON c.TreatmentYear = n.TreatmentYear
LEFT JOIN 
    NextLineFor_CD38_Patients_Time nt ON c.TreatmentYear = nt.TreatmentYear
GROUP BY 
    c.TreatmentYear
ORDER BY 
    c.TreatmentYear;

---------------------------------------------------------------------




WITH RelevantPatients AS (
    SELECT DISTINCT PATIENTID
    FROM big_lot_table_8
)

SELECT 
    EXTRACT(YEAR FROM episodedate) AS Year,
    COUNT(DISTINCT patientid) AS CountOfUniquePatients
FROM PROD_CCHC.SANOFI.MM_FLRN_DRUGEPISODE_0901
WHERE patientid IN (SELECT PATIENTID FROM RelevantPatients)
AND (drugname ILIKE '%daratumumab%' OR drugname ILIKE '%isatuximab%')
GROUP BY EXTRACT(YEAR FROM episodedate)
ORDER BY EXTRACT(YEAR FROM episodedate) ASC;



select year(diagnosisdate)*100+Month(diagnosisdate) as dx_year,count( distinct patientid) as pat_count
from PROD_CCHC.SANOFI.MM_FLRN_DIAGNOSIS_0901
where dx_year between 201601 and 202307
-- where patientid in (select patientid from big_lot_table_8 where line_zero_flag = 0)
group by dx_year
order by dx_year asc;


-- SQL code to get a count of distinct patients by year in the DrugEpisode table, starting in 2013
-- SQL code to get a count of distinct patients by their earliest year in the DrugEpisode table, starting in 2013
WITH PatientFirstYear AS (
    SELECT
        PatientID,
        MIN(EXTRACT(YEAR FROM LineStartDate)) AS FirstYear
    FROM
        PROD_CCHC.SANOFI.MM_FLRN_DRUGEPISODE_0901
    GROUP BY
        PatientID
)

SELECT
    FirstYear AS Year,
    COUNT(DISTINCT PatientID) AS DistinctPatientCount
FROM
    PatientFirstYear
WHERE
    FirstYear >= 2013
GROUP BY
    FirstYear
ORDER BY
    Year;


select year(episodedate)*100+Month(episodedate) as drug_year_month,count( distinct patientid) as pat_count,linenumber
from PROD_CCHC.SANOFI.MM_FLRN_DRUGEPISODE_0901
where drug_year_month between 201601 and 202307
and patientid in (select patientid from big_lot_table_8 where line_zero_flag = 0)
group by drug_year_month,linenumber
order by drug_year_month,linenumber asc;




WITH RECURSIVE Calendar AS (
    SELECT 201504 AS TreatmentYear -- Start from January 2016
    UNION ALL
    SELECT TreatmentYear + CASE
                            WHEN MOD(TreatmentYear, 100) = 12 THEN 89  -- If it's December, add 89 to move to January of next year
                            ELSE 1 -- Otherwise, just add 1 to go to next month
                           END
    FROM Calendar
    WHERE TreatmentYear < 202307 -- Stop at July 2023
),
FilteredPatients AS (
    SELECT DISTINCT PATIENTID
    FROM big_lot_table_8 
    WHERE line_zero_flag = 0
)

SELECT 
    c.TreatmentYear AS drug_year_month,
    COALESCE(COUNT(DISTINCT CASE WHEN linenumber = 1 THEN patientid ELSE NULL END), 0) AS "1",
    COALESCE(COUNT(DISTINCT CASE WHEN linenumber = 2 THEN patientid ELSE NULL END), 0) AS "2",
    COALESCE(COUNT(DISTINCT CASE WHEN linenumber = 3 THEN patientid ELSE NULL END), 0) AS "3",
    COALESCE(COUNT(DISTINCT CASE WHEN linenumber >= 4 THEN patientid ELSE NULL END), 0) AS "4+",
    COALESCE(COUNT(DISTINCT CASE WHEN linenumber = 0 THEN patientid ELSE NULL END), 0) AS "Other"
FROM Calendar c
LEFT JOIN PROD_CCHC.SANOFI.MM_FLRN_DRUGEPISODE_0901 d
ON c.TreatmentYear = EXTRACT(YEAR FROM d.episodedate) * 100 + EXTRACT(MONTH FROM d.episodedate)
AND d.patientid IN (SELECT PATIENTID FROM FilteredPatients)
AND (d.drugname LIKE '%daratumumab%' OR d.drugname LIKE '%isatuximab%')
GROUP BY c.TreatmentYear
ORDER BY c.TreatmentYear ASC;

WITH RECURSIVE Calendar AS (
    SELECT 202207 AS TreatmentYear -- Start from January 2016
    UNION ALL
    SELECT TreatmentYear + CASE
                            WHEN MOD(TreatmentYear, 100) = 12 THEN 89  -- If it's December, add 89 to move to January of next year
                            ELSE 1 -- Otherwise, just add 1 to go to next month
                           END
    FROM Calendar
    WHERE TreatmentYear < 202307 -- Stop at July 2023
),
FilteredPatients AS (
    SELECT DISTINCT PATIENTID
    FROM big_lot_table_8 
    -- WHERE line_zero_flag = 0
)

SELECT 
    c.TreatmentYear AS drug_year_month,
    COALESCE(COUNT(DISTINCT CASE WHEN linenumber = 1 THEN patientid ELSE NULL END), 0) AS "1",
    COALESCE(COUNT(DISTINCT CASE WHEN linenumber = 2 THEN patientid ELSE NULL END), 0) AS "2",
    COALESCE(COUNT(DISTINCT CASE WHEN linenumber = 3 THEN patientid ELSE NULL END), 0) AS "3",
    COALESCE(COUNT(DISTINCT CASE WHEN linenumber >= 4 THEN patientid ELSE NULL END), 0) AS "4+",
    COALESCE(COUNT(DISTINCT CASE WHEN linenumber = 0 THEN patientid ELSE NULL END), 0) AS "Other"
FROM Calendar c
LEFT JOIN PROD_CCHC.SANOFI.MM_FLRN_DRUGEPISODE_0901 d
ON c.TreatmentYear = EXTRACT(YEAR FROM d.episodedate) * 100 + EXTRACT(MONTH FROM d.episodedate)
AND d.patientid IN (SELECT PATIENTID FROM FilteredPatients)
GROUP BY c.TreatmentYear
ORDER BY c.TreatmentYear ASC;


WITH RECURSIVE Calendar AS (
    SELECT 201504 AS TreatmentYear -- Start from January 2016
    UNION ALL
    SELECT TreatmentYear + CASE
                            WHEN MOD(TreatmentYear, 100) = 12 THEN 89  -- If it's December, add 89 to move to January of next year
                            ELSE 1 -- Otherwise, just add 1 to go to next month
                           END
    FROM Calendar
    WHERE TreatmentYear < 202307 -- Stop at July 2023
),
FilteredPatients AS (
    SELECT DISTINCT PATIENTID
    FROM big_lot_table_8 
    -- WHERE line_zero_flag = 0
)

SELECT 
    c.TreatmentYear AS drug_year_month,
    COALESCE(COUNT(DISTINCT CASE WHEN linenumber = 1 THEN patientid ELSE NULL END), 0) AS "1",
    COALESCE(COUNT(DISTINCT CASE WHEN linenumber = 2 THEN patientid ELSE NULL END), 0) AS "2",
    COALESCE(COUNT(DISTINCT CASE WHEN linenumber = 3 THEN patientid ELSE NULL END), 0) AS "3",
    COALESCE(COUNT(DISTINCT CASE WHEN linenumber >= 4 THEN patientid ELSE NULL END), 0) AS "4+",
    COALESCE(COUNT(DISTINCT CASE WHEN linenumber = 0 THEN patientid ELSE NULL END), 0) AS "Other"
FROM Calendar c
LEFT JOIN big_lot_table_8 d
ON c.TreatmentYear = EXTRACT(YEAR FROM d.startdate) * 100 + EXTRACT(MONTH FROM d.startdate)
AND d.patientid IN (SELECT PATIENTID FROM FilteredPatients)
and isfirsttreatment = 1
and cd38_flag = 1
GROUP BY c.TreatmentYear
ORDER BY c.TreatmentYear ASC;

WITH RECURSIVE Calendar AS (
    SELECT 201504 AS TreatmentYear -- Start from April 2015
    UNION ALL
    SELECT TreatmentYear + CASE
                            WHEN MOD(TreatmentYear, 100) = 12 THEN 89  -- If it's December, add 89 to move to January of next year
                            ELSE 1 -- Otherwise, just add 1 to go to next month
                           END
    FROM Calendar
    WHERE TreatmentYear < 202307 -- Stop at July 2023
),
FilteredPatients AS (
    SELECT DISTINCT PATIENTID
    FROM big_lot_table_8 
    WHERE line_zero_flag = 0
)

SELECT 
    c.TreatmentYear AS drug_year_month,
    COALESCE(COUNT(DISTINCT CASE WHEN linenumber = 1 THEN patientid ELSE NULL END), 0) AS "1",
    COALESCE(COUNT(DISTINCT CASE WHEN linenumber = 2 THEN patientid ELSE NULL END), 0) AS "2",
    COALESCE(COUNT(DISTINCT CASE WHEN linenumber = 3 THEN patientid ELSE NULL END), 0) AS "3",
    COALESCE(COUNT(DISTINCT CASE WHEN linenumber >= 4 THEN patientid ELSE NULL END), 0) AS "4+",
    COALESCE(COUNT(DISTINCT CASE WHEN linenumber = 0 THEN patientid ELSE NULL END), 0) AS "Other"
FROM Calendar c
LEFT JOIN PROD_CCHC.SANOFI.MM_FLRN_DRUGEPISODE_0901 d
ON d.episodedate BETWEEN TO_DATE(TO_VARCHAR(c.TreatmentYear) || '01', 'YYYYMMDD')
                     AND DATEADD(DAY, -1, DATE_TRUNC('MONTH', DATEADD(MONTH, 1, TO_DATE(TO_VARCHAR(c.TreatmentYear) || '01', 'YYYYMMDD'))))
AND d.patientid IN (SELECT PATIENTID FROM FilteredPatients)
AND (d.drugname LIKE '%daratumumab%' OR d.drugname LIKE '%isatuximab%')
GROUP BY c.TreatmentYear
ORDER BY c.TreatmentYear ASC;

-- Create Sankey Data
create or replace temporary table sankey_table as
select patientid,linenumber,regimen,year(startdate) as start_year,len_flag,cd38_flag,cd38_exposed_flag,transplant_flag,len_refractory_flag
from big_lot_table_8
where line_zero_flag = 0
and isfirsttreatment = 1;


create or replace temporary table two_plus_SCT_patients as
select patientid 
from big_lot_table_8
where line_zero_flag = 0
and linename like '%Transplant%'
and linenumber >= 2;

create or replace temporary table two_plus_SCT_examples as
select patientid,linenumber,linename,combinedline
from big_lot_table_8
where line_zero_flag = 0
and patientid in (select patientid from two_plus_SCT_patients)
group by patientid,linenumber,linename,combinedline
order by patientid,linenumber asc;

select count(distinct patientid)
from two_plus_sct_examples;
-- where linename like '%Clinical Study Drug%';

create or replace temporary table maintenance_patients as 
select patientid
from big_lot_table_8
where line_zero_flag = 0
and ismaintenancetherapy like 'True';

select * from big_lot_table_8
where patientid like 'F66348EDDFC86'
and transplant_flag = 1;

select count(distinct patientid)
from big_lot_table_8
where line_zero_flag = 0
and isfirsttreatment = 1
and transplant_flag = 1
and cd38_flag = 1
and linenumber = 2
and startdate >= '2022-07-31';

select count(distinct patientid),year(EPISODEDATE)
from PROD_CCHC.SANOFI.MM_FLRN_DRUGEPISODE_0901
where linename like '%Daratumumab%'
group by year(EPISODEDATE)
order by year(EPISODEDATE) desc;

select count(distinct patientid) ,year(diagnosisdate)
from PROD_CCHC.SANOFI.MM_FLRN_MM_MULTIPLEMYELOMA_0901
group by year(diagnosisdate)
order by year(diagnosisdate) desc;

select count(distinct patientid),linenumber
from big_lot_table_8
where line_zero_flag = 0
and cd38_flag = 1
and year(startdate) = 2022
group by linenumber;