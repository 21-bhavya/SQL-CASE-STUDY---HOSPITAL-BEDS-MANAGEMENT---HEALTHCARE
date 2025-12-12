-- List all unique hospital services available in the hospital.
SELECT DISTINCT SERVICE
FROM services_weekly

--Find all patients admitted to 'Surgery' service with a satisfaction score below 70, showing their patient_id, name, age, and satisfaction score.

SELECT PATIENT_ID,NAME,AGE,SATISFACTION
FROM PATIENTS
WHERE SERVICE = 'SURGERY' AND SATISFACTION < 70

--List all patients sorted by age in descending order.
SELECT PATIENT_ID,NAME,AGE 
FROM PATIENTS
ORDER BY AGE DESC

--Show all services_weekly data sorted by week number ascending and patients_request descending.
SELECT * FROM SERVICES_WEEKLY
ORDER BY WEEK ASC , PATIENTS_REQUEST DESC

--Display staff members sorted alphabetically by their names.
SELECT * FROM STAFF
ORDER BY STAFF_NAME ASC

--Retrieve the top 5 weeks with the highest patient refusals across all services, showing week, service, patients_refused, and patients_request. Sort by patients_refused in descending order.
SELECT TOP 5 WEEK,SERVICE,PATIENTS_REFUSED,PATIENTS_REQUEST
FROM SERVICES_WEEKLY
ORDER BY PATIENTS_REFUSED DESC

--Display the first 5 patients from the patients table
SELECT TOP 5 PATIENT_ID,NAME,AGE FROM PATIENTS

--Show patients 11-20 using OFFSET.
SELECT PATIENT_ID,
       NAME,
	   AGE 
FROM PATIENTS
ORDER BY PATIENT_ID
OFFSET 10 ROWS
FETCH NEXT 10 ROWS ONLY

--Get the 10 most recent patient admissions based on arrival_date.
SELECT * 
FROM PATIENTS
ORDER BY ARRIVAL_DATE DESC
OFFSET 0 ROWS
FETCH NEXT 10 ROWS ONLY

--Find the 3rd to 7th highest patient satisfaction scores from the patients table, showing patient_id, name, service, and satisfaction. 
--Display only these 5 records.

SELECT PATIENT_ID,
       NAME,
	   SERVICE,
	   SATISFACTION
FROM PATIENTS
ORDER BY SATISFACTION DESC,PATIENT_ID ASC
OFFSET 2 ROWS
FETCH NEXT 5 ROWS ONLY

--1. Extract the year from all patient arrival dates.
SELECT ARRIVAL_DATE ,DATEPART(YEAR , ARRIVAL_DATE) AS ARRIVAL_YEAR FROM PATIENTS

--2. Calculate the length of stay for each patient (departure_date - arrival_date).
SELECT PATIENT_ID, DATEDIFF(DAY,ARRIVAL_DATE,DEPARTURE_DATE) AS LENGTH_OF_STAY FROM PATIENTS

--3. Find all patients who arrived in a specific month.
SELECT PATIENT_ID ,ARRIVAL_DATE, DATEPART(MONTH,ARRIVAL_DATE) AS ARRIVAL_MONTH FROM PATIENTS
WHERE DATENAME(MONTH,ARRIVAL_DATE) = 'JANUARY'
ORDER BY ARRIVAL_DATE

---- Calculate the total number of patients admitted, total patients refused, 
--and the average patient satisfaction across all services and weeks.
--Round the average satisfaction to 2 decimal places.

SELECT SUM(PATIENTS_ADMITTED) AS TOT_PATIENTS_ADMITTED,
       SUM( PATIENTS_REFUSED) AS TOT_PATIENTS_REFUSED,
	   ROUND(AVG(PATIENT_SATISFACTION),2) AS AVG_SATISFACTION_SCORE
FROM services_weekly


--Calculate the average length of stay (in days) for each service, showing only services where the average stay is more than 7 days. 
--Also show the count of patients and order by average stay descending.

SELECT SERVICE,AVG(DATEDIFF(DAY,ARRIVAL_DATE,DEPARTURE_DATE)) AS AVG_STAY,
COUNT(PATIENT_ID) AS PATIENTS_COUNT FROM PATIENTS
GROUP BY SERVICE
HAVING AVG(DATEDIFF(DAY,ARRIVAL_DATE,DEPARTURE_DATE)) > 7
ORDER BY AVG_STAY DESC


--Create a trend analysis showing for each service and week: week number, patients_admitted, 
--running total of patients admitted (cumulative), 3-week moving average of patient satisfaction 
--(current week and 2 prior weeks), and the difference between current week admissions and the service average. 
--Filter for weeks 10-20 only
SELECT SERVICE,
       WEEK, 
       PATIENTS_ADMITTED,
       SUM(PATIENTS_ADMITTED) OVER (PARTITION BY SERVICE 
	                                ORDER BY WEEK) AS RUNNING_TOTAL,
       AVG(PATIENT_SATISFACTION) OVER (PARTITION BY SERVICE 
	                                   ORDER BY WEEK 
									   ROWS BETWEEN 2 PRECEDING AND CURRENT ROW ) AS MOVING_AVG_SAT,
       (PATIENTS_ADMITTED - AVG(PATIENTS_ADMITTED) OVER(PARTITION BY SERVICE )) AS DIFFERENCE_FROM_AVG
FROM SERVICES_WEEKLY
WHERE WEEK BETWEEN 10 AND 20
ORDER BY SERVICE,WEEK

--for  each service, rank the weeks by patient satisfaction score (highest first).
--Show service, week, patient_satisfaction, patients_admitted, and the rank. 
--Include only the top 3 weeks per service.
SELECT * FROM  (

SELECT SERVICE, 
       WEEK, 
       PATIENT_SATISFACTION , 
       PATIENTS_ADMITTED,
       RANK() OVER(PARTITION BY SERVICE ORDER BY PATIENT_SATISFACTION DESC) AS RANKS
FROM SERVICES_WEEKLY) AS info
WHERE RANKS <=3;

--Create a report showing each service with:
--service name, total patients admitted, the difference between their total admissions and the average admissions across all services, 
--and a rank indicator ('Above Average', 'Average', 'Below Average'). 
--Order by total patients admitted descending.


SELECT 
    S.SERVICE,
    SUM(S.PATIENTS_ADMITTED) AS TOT_PATIENTS_ADMITTED,
    SUM(S.PATIENTS_ADMITTED) 
        - (SELECT AVG(PATIENTS_ADMITTED) FROM SERVICES_WEEKLY) AS DIFF_FROM_AVG,
    CASE
        WHEN SUM(S.PATIENTS_ADMITTED) > (SELECT AVG(PATIENTS_ADMITTED) FROM SERVICES_WEEKLY)
        THEN 'Above Average'
        WHEN SUM(S.PATIENTS_ADMITTED) = (SELECT AVG(PATIENTS_ADMITTED) FROM SERVICES_WEEKLY)
        THEN 'Average'
        ELSE 'Below Average'
    END AS RANK_INDICATOR
FROM SERVICES_WEEKLY S
GROUP BY S.SERVICE;

--Create a comprehensive personnel and patient list showing:
--identifier (patient_id or staff_id), full name, type ('Patient' or 'Staff'), 
--and associated service. Include only those in 'surgery' or 'emergency' services.
--Order by type, then service, then name.



SELECT PATIENT_ID AS ID_NO,
       NAME, 
      'PATIENT' AS TYPE,
       SERVICE
FROM PATIENTS
WHERE SERVICE = 'emergency' or service = 'surgery'
UNION ALL
SELECT STAFF_ID AS ID_NO,
       STAFF_NAME AS NAME,
      'STAFF' AS TYPE , 
       SERVICE 
FROM STAFF
WHERE SERVICE = 'emergency' or service = 'surgery'
ORDER BY TYPE,SERVICE,NAME

--Create a comprehensive service analysis report for week 20 showing: 
--service name, total patients admitted that week, total patients refused, average patient satisfaction,
--count of staff assigned to service, and count of staff present that week. 
---Order by patients admitted descending.

SELECT * FROM staff_schedule
SELECT * FROM services_weekly
SELECT * FROM staff
SELECT S.SERVICE,
SUM(PATIENTS_ADMITTED) AS TOT_PATIENTS_ADMTD,
SUM(PATIENTS_REFUSED) AS TOT_PATIENTS_REFUSED,
AVG(PATIENT_SATISFACTION) AS AVG_SAT,
COUNT(DISTINCT SS.STAFF_ID) AS COUNT_OF_STAFF,
COUNT(DISTINCT CASE WHEN SS.PRESENT = 1 THEN SS.STAFF_ID END) AS COUNT_PRESENT
FROM SERVICES_WEEKLY S LEFT JOIN STAFF_SCHEDULE SS
ON S.SERVICE = SS.SERVICE
AND S.WEEK = SS.WEEK
WHERE S.WEEK = 20
GROUP BY S.SERVICE
ORDER BY TOT_PATIENTS_ADMTD DESC

SELECT 
    sw.service,
    SUM(sw.patients_admitted) AS total_patients_admitted,
    SUM(sw.patients_refused) AS total_patients_refused,
    AVG(sw.patient_satisfaction) AS avg_patient_satisfaction,
    COUNT(DISTINCT ss.staff_id) AS staff_assigned,
    COUNT(DISTINCT CASE WHEN ss.present = 1 THEN ss.staff_id END) AS staff_present
FROM SERVICES_WEEKLY sw
LEFT JOIN STAFF_SCHEDULE ss
       ON sw.service = ss.service
      AND sw.week = ss.week
WHERE sw.week = 20
GROUP BY sw.service
ORDER BY total_patients_admitted DESC
