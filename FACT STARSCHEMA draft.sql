--SQL STATEMENTS.
--Creation:
CREATE TABLE APPLICATION AS
SELECT * FROM DW_CAREER.APPLICATION;

CREATE TABLE CANDIDATE AS
SELECT * FROM DW_CAREER.CANDIDATE;

CREATE TABLE COMPANY AS
SELECT * FROM DW_CAREER.COMPANY;

CREATE TABLE DEGREE AS
SELECT * FROM DW_CAREER.DEGREE;

CREATE TABLE EMPLOYER AS
SELECT * FROM DW_CAREER.EMPLOYER;

CREATE TABLE E_ORGANIZATION AS
SELECT * FROM DW_CAREER.E_ORGANIZATION;

CREATE TABLE INDUSTRY AS
SELECT * FROM DW_CAREER.INDUSTRY;

CREATE TABLE JOB_POSTING AS
SELECT * FROM DW_CAREER.JOB_POSTING;

CREATE TABLE JOB_TITLE AS
SELECT * FROM DW_CAREER.JOB_TITLE;

CREATE TABLE LOCATION AS
SELECT * FROM DW_CAREER.LOCATION;  

CREATE TABLE OPERATING AS
SELECT * FROM DW_CAREER.OPERATING;
--COPY ALL DATABASE TABLES FROM THE ACCOUNT DW_CAREER TO OWN ACCOUNT.




--Droppin� Tables: *To check stuff
--DROP TABLE APPLICATION;

--DROP TABLE CANDIDATE;

--DROP TABLE COMPANY;

--DROP TABLE DEGREE;

--DROP TABLE EMPLOYER;

--DROP TABLE E_ORGANIZATION;

--DROP TABLE INDUSTRY ;

--DROP TABLE JOB_POSTING;

--DROP TABLE JOB_TITLE; 

--DROP TABLE LOCATION;

--DROP TABLE OPERATING;

--Checking Records for Data Cleaning:
SELECT COUNT(*) FROM DW_CAREER.APPLICATION;
SELECT COUNT(*) FROM DW_CAREER.CANDIDATE;
SELECT COUNT(*) FROM DW_CAREER.COMPANY;
SELECT COUNT(*) FROM DW_CAREER.DEGREE;
SELECT COUNT(*) FROM DW_CAREER.EMPLOYER;
SELECT COUNT(*) FROM DW_CAREER.E_ORGANIZATION;
SELECT COUNT(*) FROM DW_CAREER.INDUSTRY;
SELECT COUNT(*) FROM DW_CAREER.JOB_POSTING;
SELECT COUNT(*) FROM DW_CAREER.JOB_TITLE;
SELECT COUNT(*) FROM DW_CAREER.LOCATION;
SELECT COUNT(*) FROM DW_CAREER.OPERATING;
--  CHECK HOW MANY RECORDS IN EACH TABLE BEFORE DATA CLEANING



--Star Schema Creation/Insert:
/*COMPANY_OPERATING_YEAR_DIM
COMPANY_SIZE_DIM
COMPANY_DIM
EMPLOYER_TYPE_DIM
LOCATION_DIM
INDUSTRY_DIM
JOB_TITLE_DIM
JOB_EXPERIENCE_LEVEL_DIM
E_ORGANISATION_DIM
JOB_POSTING_YEAR_DIM
CANDIDATE_GENDER_DIM
JOB_WORK_TYPE_DIM

TEMPFACTS AND FACTS*/

CREATE TABLE INDUSTRY_DIM AS
SELECT INDUSTRY_ID,INDUSTRY_NAME
FROM INDUSTRY;

CREATE TABLE LOCATION_DIM AS
SELECT LOCATION_ID,CITY,STATE,COUNTRY
FROM LOCATION;

CREATE TABLE COMPANY_DIM AS
SELECT COMPANY_ID
FROM COMPANY;

CREATE TABLE JOB_TITLE_DIM AS
SELECT JOB_TITLE_ID,JOB_TITLE
FROM JOB_TITLE;

CREATE TABLE JOB_EXPERIENCE_LEVEL_DIM (
  JOB_EXPERIENCE_ID VarChar2(10),
  JOB_EXPERIENCE_LEVEL VarChar2(20)
);

INSERT INTO JOB_EXPERIENCE_LEVEL_DIM
VALUES('1','Graduate');
INSERT INTO JOB_EXPERIENCE_LEVEL_DIM
VALUES('2','Junior');
INSERT INTO JOB_EXPERIENCE_LEVEL_DIM
VALUES('3','Middle');
INSERT INTO JOB_EXPERIENCE_LEVEL_DIM
VALUES('4','Senior');

CREATE TABLE EMPLOYER_TYPE_DIM (
  EMPLOYER_TYPE_ID VarChar2(10),
  EMPLOYER_TYPE VarChar2(20)
);

INSERT INTO EMPLOYER_TYPE_DIM
VALUES('1','Direct Employer');
INSERT INTO EMPLOYER_TYPE_DIM
VALUES('2','Recruitment Agency');
INSERT INTO EMPLOYER_TYPE_DIM
VALUES('3','Government');

CREATE TABLE JOB_WORK_TYPE_DIM (
  JOB_WORK_TYPE_ID VarChar2(10),
  JOB_WORK_TYPE VarChar2(20)
);

INSERT INTO JOB_WORK_TYPE_DIM
VALUES('FT','Full Time');

INSERT INTO JOB_WORK_TYPE_DIM
VALUES('PT','Part Time');

INSERT INTO JOB_WORK_TYPE_DIM
VALUES('CT','Contract');

INSERT INTO JOB_WORK_TYPE_DIM
VALUES('CS','Casual');

CREATE TABLE GENDER_DIM AS
SELECT DISTINCT(gender)
FROM CANDIDATE;

CREATE TABLE JOB_POSTING_YEAR_DIM AS 
SELECT DISTINCT(EXTRACT(YEAR FROM posting_date)) AS JOB_POSTING_YEAR
FROM JOB_POSTING;

CREATE TABLE COMPANY_DIM AS
SELECT Company_ID
FROM COMPANY;

--listAGG DIM + FACT x2 TO BE CONTINUE
CREATE TABLE E_ORGNIZATION_DIM AS
SELECT ORGANIZATION_ID,ORGANIZATION_TYPE,ORGANIZATION_NAME
FROM E_ORGANIZATION;

CREATE TABLE BRIDGE_TABLE AS 
SELECT c.candidate_id,e.organization_id
FROM candidate c,e_organization e,degree d
WHERE c.candidate_id = d.holder_id AND e.organization_id = d.organization_id;

CREATE TABLE CANDIDATE_DIM AS
SELECT candidate_id, 
  (SELECT 1/COUNT(organization_id) FROM BRIDGE_TABLE GROUP BY candidate_id )AS Weight_Factor, 
  (SELECT LISTAGG (organization_id,'_')Within Group(Order By organization_id) FROM BRIDGE_TABLE)AS e_org_list
FROM candidate;--error

CREATE TABLE APPLICATION_TEMP AS 
SELECT ca.candidate_id,EXTRACT(YEAR FROM jp.POSTING_DATE)AS Year,ca.gender,jp.work_type AS job_work_type,jp.years_experience,e.employer_type
/*,job_experience_id*/,jt.job_title_id,e.company_id,jp.location_id,jt.industry_id
FROM candidate ca,job_posting jp, employer e,job_title jt,application a
WHERE jp.employer_id = e.employer_id AND jp.job_title_id = jt.job_title_id AND jp.job_posting_id = a.job_posting_id AND a.candidate_id = ca.candidate_id;


ALTER TABLE APPLICATION_TEMP
ADD (job_experience_id Number);

UPDATE APPLICATION_TEMP
SET job_experience_id = 1
WHERE years_experience = 1;

UPDATE APPLICATION_TEMP
SET job_experience_id = 2
WHERE years_experience >= 1 AND years_experience <=2;

UPDATE APPLICATION_TEMP
SET job_experience_id = 3
WHERE years_experience >= 2 AND years_experience <=5;

UPDATE APPLICATION_TEMP
SET job_experience_id = 4
WHERE years_experience >5;


CREATE TABLE APPLICATION_FACT AS --ERROR
SELECT candidate_id,Year,gender,job_work_type,job_experience_id,employer_type,job_title_id,company_id,location_id,industry_id
  count(a.job_posting_id,a.candidate_id) AS TOTAL_NUMBER_APPLICATION,
  (SELECT count(job_posting_id,candidate_id)FROM application Having success = 'N') AS TOTAL_NUMBER_FAILED,--??
  (TOTAL_NUMBER_APPLICATION - TOTAL_NUMBER_FAILED) AS TOTAL_NUMBER_SUCCESS,
  SUM(j.recruitment_commision*(SELECT COUNT(job_posting_id,candidate_id)FROM application Having success = 'Y')) AS TOTAL_REVENUE--?
FROM APPLICATION_TEMP
GROUP BY candidate_id,Year,gender,job_work_type,job_experience_id,employer_type,job_title_id,company_id,location_id,industry_id;

--COMPANY FACT SERIES

CREATE TABLE COMPANY_OPERATING_YEAR_DIM AS 
SELECT DISTINCT( year) AS COMPANY_OPERATING_YEAR
FROM OPERATING;

CREATE TABLE COMPANY_SIZE_DIM
(
  COMPANY_SIZE_ID VarChar2(10),
  COMPANY_SIZE_TYPE VarChar2(20)
);

INSERT INTO COMPANY_SIZE_DIM 
VALUES('1','Small');
INSERT INTO COMPANY_SIZE_DIM 
VALUES('2','Medium');
INSERT INTO COMPANY_SIZE_DIM 
VALUES('3','Big');

CREATE TABLE COMPANY_TEMP AS
SELECT company_id,number_of_employees,year,industry_id,location_id
FROM operating;

ALTER TABLE COMPANY_TEMP 
ADD (company_size_id Number);


UPDATE COMPANY_TEMP
SET company_size_id = 1
HAVING SUM(number_of_employee)<100
GROUP BY company_id;

UPDATE COMPANY_TEMP--invalid table name
SET company_size_id = 1
SUM(number_of_employee)) AS "SUM"
FROM 
FROM COMPANY_TEMP GROUP BY company_id)<100;

/*SELECT order_details.department,
SUM(order_details.sales) AS "Total sales"
FROM order_details, (SELECT department, SUM(sales) AS "Sales_compare"
                     FROM order_details
                     GROUP BY department) subquery1
WHERE order_details.department = subquery1.department
AND subquery1.Sales_compare > 1000
GROUP BY order_details.department;*/

UPDATE TABLE COMPANY_TEMP
SET company_size_id = 2
WHERE (SUM(number_of_employee) FROM COMPANY_TEMP GROUP BY company_id)>=100 AND (SUM(number_of_employee) FROM COMPANY_TEMP GROUP BY company_id)<=500;

UPDATE TABLE COMPANY_TEMP
SET company_size_id = 1
WHERE (SUM(number_of_employee) FROM COMPANY_TEMP GROUP BY company_id)>500;


CREATE TABLE COMPANY_FACT AS --single-row subquery returns more than one row
SELECT company_size_id,year,industry_id,location_id,
  (SELECT SUM(number_of_employees) FROM COMPANY_TEMP GROUP BY company_id) AS TOTAL_NUMBER_EMPLOYEE,
  COUNT(DISTINCT(company_id)) AS TOTAL_NUMBER_COMPANIES
FROM COMPANY_TEMP
GROUP BY company_size_id,year,industry_id,location_id;

--DROPPING DIMS AND FACTS
/*COMPANY_OPERATING_YEAR_DIM
*/
DROP TABLE COMPANY_SIZE_DIM;
DROP TABLE COMPANY_DIM;
DROP TABLE EMPLOYER_TYPE_DIM;
DROP TABLE LOCATION_DIM;
DROP TABLE INDUSTRY_DIM;
DROP TABLE JOB_TITLE_DIM;
DROP TABLE JOB_EXPERIENCE_LEVEL_DIM;
DROP TABLE E_ORGANISATION_DIM;
DROP TABLE JOB_POSTING_YEAR_DIM;
DROP TABLE CANDIDATE_GENDER_DIM;
DROP TABLE JOB_WORK_TYPE_DIM;


DROP TABLE E_ORGNIZATION_DIM;
                
DROP TABLE BRIDGE_TABLE;

DROP TABLE CANDIDATE_DIM;

DROP TABLE APPLICATOIN_TEMP;
DROP TABLE BRIDGE_TABLE;
DROP TABLE COMPANY_OPERATING_YEAR_DIM;
DROP TABLE GENDER_DIM;
DROP TABLE EMPLOYERY;
DROP TABLE COMPANY_DIM;