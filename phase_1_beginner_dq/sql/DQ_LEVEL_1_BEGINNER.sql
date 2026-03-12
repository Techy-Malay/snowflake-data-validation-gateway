/***********************************************************************
  SNOWFLAKE DATA VALIDATION GATEWAY
  Author: Malaya Kumar Padhi
  LinkedIn: https://www.linkedin.com/in/mkpadhi/
  GitHub: https://github.com/Techy-Malay/snowflake-data-validation-gateway
  
  ============================================================
       BEGINNER LEVEL - "My First Data Quality Check"
  ============================================================
  
  SKILL LEVEL: Beginner (Just started learning SQL)
  TIME TO COMPLETE: 15-20 minutes
  PREREQUISITES: Basic SELECT, INSERT, CREATE TABLE knowledge
  
  WHAT YOU WILL LEARN:
    - How to check for NULL (empty) values
    - How to check for duplicates
    - How to check value ranges
    - How to separate good data from bad data
    - How to use CASE WHEN (if-then-else in SQL)
  
  HOW TO USE THIS FILE:
    - Run each section one at a time (top to bottom)
    - Read the comments BEFORE running each query
    - Look at the results AFTER running each query
    - Each step builds on the previous one
  
  NO stored procedures. NO dynamic SQL. NO cursors.
  Just plain, simple SQL that anyone can understand.
***********************************************************************/


-- =================================================================
--  STEP 1: BUILD OUR PLAYGROUND
--  
--  Think of this like setting up a desk before doing work.
--  We need a database (a big folder) and a schema (a sub-folder).
-- =================================================================

CREATE DATABASE IF NOT EXISTS DQ_BEGINNER_LAB;
USE DATABASE DQ_BEGINNER_LAB;
CREATE SCHEMA IF NOT EXISTS PRACTICE;
USE SCHEMA PRACTICE;

-- Let's use any available warehouse
-- (If you don't have one, uncomment the line below)
-- CREATE WAREHOUSE IF NOT EXISTS MY_WH WAREHOUSE_SIZE = 'X-SMALL' AUTO_SUSPEND = 60 AUTO_RESUME = TRUE;
-- USE WAREHOUSE MY_WH;


-- =================================================================
--  STEP 2: CREATE OUR DATA TABLE
--  
--  Imagine this is a spreadsheet where customer orders are entered.
--  Sometimes people make mistakes when entering data.
--  Our job: FIND those mistakes.
-- =================================================================

CREATE OR REPLACE TABLE ORDERS_RAW (
    ROW_NUM         NUMBER AUTOINCREMENT,   -- Auto-numbers each row: 1, 2, 3...
    CUSTOMER_NAME   VARCHAR(200),           -- Customer's name (text)
    EMAIL           VARCHAR(500),           -- Email address (text)
    ORDER_ID        NUMBER,                 -- Order number
    ORDER_DATE      DATE,                   -- When the order was placed
    ORDER_AMOUNT    NUMBER(10,2),           -- How much the order costs (dollars.cents)
    COUNTRY         VARCHAR(50)             -- Which country
);


-- =================================================================
--  STEP 3: INSERT SAMPLE DATA
--  
--  We'll put in 8 rows. Some are GOOD, some are BAD.
--  Can you spot the problems? (Answers revealed in the checks below!)
--  
--  ROW 1: Perfect record
--  ROW 2: Perfect record
--  ROW 3: Missing customer name (NULL)
--  ROW 4: Missing email AND order amount is negative
--  ROW 5: Order date is in the future (impossible!)
--  ROW 6: Duplicate order ID (same as Row 1)
--  ROW 7: Order amount is zero
--  ROW 8: Perfect record
-- =================================================================

INSERT INTO ORDERS_RAW (CUSTOMER_NAME, EMAIL, ORDER_ID, ORDER_DATE, ORDER_AMOUNT, COUNTRY)
VALUES
    ('Alice Smith',   'alice@email.com',   101, '2025-03-01',  250.00, 'USA'),
    ('Bob Jones',     'bob@email.com',     102, '2025-03-05',  175.50, 'Canada'),
    (NULL,            'mystery@email.com', 103, '2025-02-15',  500.00, 'UK'),
    ('Dave Wilson',   NULL,                104, '2025-01-20', -100.00, 'USA'),
    ('Eve Brown',     'eve@email.com',     105, '2029-12-31',  300.00, 'Germany'),
    ('Frank Lee',     'frank@email.com',   101, '2025-03-10',  425.00, 'USA'),
    ('Grace Kim',     'grace@email.com',   107, '2025-02-28',    0.00, 'Japan'),
    ('Henry Park',    'henry@email.com',   108, '2025-03-08',  890.00, 'Australia');


-- Let's see all our data first
SELECT * FROM ORDERS_RAW ORDER BY ROW_NUM;


-- =================================================================
--  STEP 4: CHECK #1 - FIND ROWS WHERE CUSTOMER_NAME IS EMPTY
--  
--  NULL means "no value" or "blank."
--  A customer order MUST have a name. 
--  If it's NULL, something went wrong during data entry.
--  
--  SQL Concept: IS NULL
-- =================================================================

SELECT 
    ROW_NUM,
    CUSTOMER_NAME,
    EMAIL,
    ORDER_ID,
    'FAIL: Customer Name is missing' AS CHECK_RESULT
FROM ORDERS_RAW
WHERE CUSTOMER_NAME IS NULL;

-- EXPECTED: Row 3 appears here (it has no customer name)


-- =================================================================
--  STEP 5: CHECK #2 - FIND ROWS WHERE EMAIL IS EMPTY
--  
--  Same idea. Every order should have an email for confirmation.
-- =================================================================

SELECT 
    ROW_NUM,
    CUSTOMER_NAME,
    EMAIL,
    ORDER_ID,
    'FAIL: Email is missing' AS CHECK_RESULT
FROM ORDERS_RAW
WHERE EMAIL IS NULL;

-- EXPECTED: Row 4 appears here (Dave Wilson has no email)


-- =================================================================
--  STEP 6: CHECK #3 - FIND ROWS WHERE ORDER_AMOUNT IS WRONG
--  
--  An order amount should be MORE than zero.
--  Negative amounts don't make sense.
--  Zero amounts don't make sense either.
--  
--  SQL Concept: comparison operators (<=)
-- =================================================================

SELECT 
    ROW_NUM,
    CUSTOMER_NAME,
    ORDER_ID,
    ORDER_AMOUNT,
    'FAIL: Order Amount must be greater than zero' AS CHECK_RESULT
FROM ORDERS_RAW
WHERE ORDER_AMOUNT <= 0;

-- EXPECTED: Row 4 (-$100) and Row 7 ($0.00) appear here


-- =================================================================
--  STEP 7: CHECK #4 - FIND FUTURE DATES
--  
--  An order can't be placed in the future.
--  If ORDER_DATE is after today, something is wrong.
--  
--  SQL Concept: CURRENT_DATE() gives you today's date
-- =================================================================

SELECT 
    ROW_NUM,
    CUSTOMER_NAME,
    ORDER_ID,
    ORDER_DATE,
    CURRENT_DATE() AS TODAY,
    'FAIL: Order Date is in the future' AS CHECK_RESULT
FROM ORDERS_RAW
WHERE ORDER_DATE > CURRENT_DATE();

-- EXPECTED: Row 5 (Eve Brown, order date 2029-12-31) appears here


-- =================================================================
--  STEP 8: CHECK #5 - FIND DUPLICATE ORDER IDs
--  
--  Every order should have a UNIQUE order ID.
--  If two rows have the same ORDER_ID, that's a duplicate.
--  
--  SQL Concept: GROUP BY + HAVING COUNT(*) > 1
--  This groups rows by ORDER_ID and finds groups with more than 1 row.
-- =================================================================

-- First, find WHICH order IDs are duplicated:
SELECT 
    ORDER_ID,
    COUNT(*) AS HOW_MANY_TIMES,
    'FAIL: This Order ID appears more than once' AS CHECK_RESULT
FROM ORDERS_RAW
GROUP BY ORDER_ID
HAVING COUNT(*) > 1;

-- EXPECTED: ORDER_ID 101 appears twice (Row 1 and Row 6)

-- Now, find the ACTUAL duplicate rows:
SELECT 
    ROW_NUM,
    CUSTOMER_NAME,
    ORDER_ID,
    ORDER_AMOUNT,
    'FAIL: Duplicate Order ID' AS CHECK_RESULT
FROM ORDERS_RAW
WHERE ORDER_ID IN (
    SELECT ORDER_ID 
    FROM ORDERS_RAW 
    GROUP BY ORDER_ID 
    HAVING COUNT(*) > 1
)
ORDER BY ORDER_ID;

-- EXPECTED: Alice (Row 1) and Frank (Row 6) both have ORDER_ID = 101


-- =================================================================
--  STEP 9: COMBINED CHECK - SEE ALL PROBLEMS IN ONE QUERY
--  
--  Now let's combine everything into ONE query.
--  
--  SQL Concept: CASE WHEN ... THEN ... ELSE ... END
--  This is like an IF-THEN-ELSE statement.
--  
--  For each row, we check multiple conditions and build
--  a "report card" showing what's wrong.
-- =================================================================

SELECT 
    ROW_NUM,
    CUSTOMER_NAME,
    EMAIL,
    ORDER_ID,
    ORDER_AMOUNT,
    ORDER_DATE,

    -- Check 1: Is customer name missing?
    CASE 
        WHEN CUSTOMER_NAME IS NULL THEN 'FAIL' 
        ELSE 'PASS' 
    END AS NAME_CHECK,

    -- Check 2: Is email missing?
    CASE 
        WHEN EMAIL IS NULL THEN 'FAIL' 
        ELSE 'PASS' 
    END AS EMAIL_CHECK,

    -- Check 3: Is order amount valid?
    CASE 
        WHEN ORDER_AMOUNT <= 0 THEN 'FAIL' 
        ELSE 'PASS' 
    END AS AMOUNT_CHECK,

    -- Check 4: Is the date in the future?
    CASE 
        WHEN ORDER_DATE > CURRENT_DATE() THEN 'FAIL' 
        ELSE 'PASS' 
    END AS DATE_CHECK,

    -- Overall verdict: If ANY check fails, the row is BAD
    CASE 
        WHEN CUSTOMER_NAME IS NULL 
          OR EMAIL IS NULL 
          OR ORDER_AMOUNT <= 0 
          OR ORDER_DATE > CURRENT_DATE() 
        THEN '** REJECT **'
        ELSE 'ACCEPT'
    END AS FINAL_VERDICT

FROM ORDERS_RAW
ORDER BY ROW_NUM;


-- =================================================================
--  STEP 10: SEPARATE GOOD DATA FROM BAD DATA
--  
--  Now let's actually MOVE the data:
--    - Good rows go to ORDERS_CLEAN
--    - Bad rows go to ORDERS_ERRORS
--  
--  This is the core idea of the full framework —
--  we're just doing it with simple SQL here.
-- =================================================================

-- Create the "CLEAN" table (for good rows)
CREATE OR REPLACE TABLE ORDERS_CLEAN AS
SELECT *
FROM ORDERS_RAW
WHERE CUSTOMER_NAME IS NOT NULL        -- Name exists
  AND EMAIL IS NOT NULL                -- Email exists
  AND ORDER_AMOUNT > 0                 -- Amount is positive
  AND ORDER_DATE <= CURRENT_DATE()     -- Date is not in future
  AND ORDER_ID NOT IN (                -- Not a duplicate
      SELECT ORDER_ID 
      FROM ORDERS_RAW 
      GROUP BY ORDER_ID 
      HAVING COUNT(*) > 1
  );

-- Create the "ERRORS" table (for bad rows)
CREATE OR REPLACE TABLE ORDERS_ERRORS AS
SELECT 
    o.*,
    CASE 
        WHEN CUSTOMER_NAME IS NULL THEN 'Missing Customer Name'
        WHEN EMAIL IS NULL THEN 'Missing Email'
        WHEN ORDER_AMOUNT <= 0 THEN 'Invalid Order Amount: ' || TO_VARCHAR(ORDER_AMOUNT)
        WHEN ORDER_DATE > CURRENT_DATE() THEN 'Future Date: ' || TO_VARCHAR(ORDER_DATE)
        ELSE 'Duplicate Order ID'
    END AS ERROR_REASON,
    CURRENT_TIMESTAMP() AS CHECKED_AT
FROM ORDERS_RAW o
WHERE CUSTOMER_NAME IS NULL
   OR EMAIL IS NULL
   OR ORDER_AMOUNT <= 0
   OR ORDER_DATE > CURRENT_DATE()
   OR ORDER_ID IN (
       SELECT ORDER_ID 
       FROM ORDERS_RAW 
       GROUP BY ORDER_ID 
       HAVING COUNT(*) > 1
   );


-- =================================================================
--  STEP 11: VIEW THE RESULTS
-- =================================================================

-- Good data (should be: Bob Jones, Henry Park)
SELECT '--- CLEAN DATA (Passed all checks) ---' AS SECTION;
SELECT ROW_NUM, CUSTOMER_NAME, EMAIL, ORDER_ID, ORDER_AMOUNT 
FROM ORDERS_CLEAN 
ORDER BY ROW_NUM;

-- Bad data (should be: all the others with error reasons)
SELECT '--- ERROR DATA (Failed one or more checks) ---' AS SECTION;
SELECT ROW_NUM, CUSTOMER_NAME, ORDER_ID, ORDER_AMOUNT, ERROR_REASON 
FROM ORDERS_ERRORS 
ORDER BY ROW_NUM;

-- Summary counts
SELECT 
    (SELECT COUNT(*) FROM ORDERS_RAW)   AS TOTAL_RECORDS,
    (SELECT COUNT(*) FROM ORDERS_CLEAN) AS CLEAN_RECORDS,
    (SELECT COUNT(*) FROM ORDERS_ERRORS) AS ERROR_RECORDS;


-- =================================================================
--  STEP 12: CLEANUP (Delete everything when done)
-- =================================================================

-- Uncomment the line below to delete the practice database:
-- DROP DATABASE IF EXISTS DQ_BEGINNER_LAB;


-- =================================================================
--  WHAT YOU LEARNED:
--  
--  1. IS NULL          - Find empty/missing values
--  2. WHERE condition  - Filter rows based on rules
--  3. CASE WHEN        - If-then-else inside SQL
--  4. GROUP BY/HAVING  - Find duplicates
--  5. CREATE TABLE AS  - Save query results as a new table
--  6. CURRENT_DATE()   - Get today's date
--  
--  NEXT STEP: Try the INTERMEDIATE file to learn:
--    - Stored procedures
--    - Error logging tables
--    - REGEXP (pattern matching)
--    - Loops and variables
-- =================================================================
