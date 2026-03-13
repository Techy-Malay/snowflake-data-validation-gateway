/***********************************************************************
  SNOWFLAKE DATA VALIDATION GATEWAY
  Author: Malaya Kumar Padhi
  LinkedIn: https://www.linkedin.com/in/mkpadhi/
  GitHub: https://github.com/Techy-Malay/snowflake-data-validation-gateway
  
  ============================================================
       INTERMEDIATE LEVEL - "Building a Real Validation System"
  ============================================================
  
  SKILL LEVEL: Intermediate (Comfortable with SQL, learning procedures)
  TIME TO COMPLETE: 30-40 minutes
  PREREQUISITES: Completed BEGINNER file, understand CASE WHEN, JOINs
  
  WHAT YOU WILL LEARN:
    - Stored Procedures (saved programs in Snowflake)
    - Variables (storing values for later use)
    - Error logging with timestamps
    - REGEXP_LIKE (pattern matching for email, phone)
    - Lookup tables for referential integrity
    - OBJECT_CONSTRUCT (building JSON objects)
    - IFF() function (shorter version of CASE WHEN)
    - Multiple schemas (organizing your database)
  
  WHAT'S DIFFERENT FROM BEGINNER:
    Beginner  = Manual queries, run each check by hand
    This file = A stored procedure does ALL checks automatically
    Advanced  = Dynamic SQL, cursors, metadata-driven (the main project)
  
  HOW TO USE THIS FILE:
    Run each section one at a time, top to bottom.
***********************************************************************/


-- =================================================================
--  STEP 1: BUILD THE ENVIRONMENT
--  
--  We create separate schemas to organize our work.
--  Think of schemas like folders on your desktop:
--    - RAW       = Where messy data arrives
--    - CLEAN     = Where good data goes
--    - ERRORS    = Where bad data goes with error details
--    - LOOKUPS   = Reference lists (valid countries, statuses)
-- =================================================================

CREATE DATABASE IF NOT EXISTS DQ_INTERMEDIATE_LAB;
USE DATABASE DQ_INTERMEDIATE_LAB;

CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS CLEAN;
CREATE SCHEMA IF NOT EXISTS ERRORS;
CREATE SCHEMA IF NOT EXISTS LOOKUPS;


-- =================================================================
--  STEP 2: CREATE LOOKUP TABLES
--  
--  A "lookup table" is an approved list.
--  When we check data, we compare values against these lists.
--  
--  Example: If someone enters country "XYZ", we check:
--           Does "XYZ" exist in our VALID_COUNTRIES list? No? FAIL.
-- =================================================================

USE SCHEMA LOOKUPS;

CREATE OR REPLACE TABLE VALID_COUNTRIES (
    COUNTRY_CODE VARCHAR(5),
    COUNTRY_NAME VARCHAR(100)
);

INSERT INTO VALID_COUNTRIES VALUES
    ('US', 'United States'), ('UK', 'United Kingdom'), ('CA', 'Canada'),
    ('DE', 'Germany'), ('FR', 'France'), ('JP', 'Japan'),
    ('AU', 'Australia'), ('IN', 'India'), ('BR', 'Brazil');

CREATE OR REPLACE TABLE VALID_STATUSES (
    STATUS_CODE VARCHAR(20),
    DESCRIPTION VARCHAR(100)
);

INSERT INTO VALID_STATUSES VALUES
    ('NEW', 'Newly placed'), ('PROCESSING', 'Being processed'),
    ('SHIPPED', 'In transit'), ('DELIVERED', 'Received by customer'),
    ('CANCELLED', 'Order cancelled'), ('RETURNED', 'Sent back');

-- Check what we created
SELECT * FROM VALID_COUNTRIES ORDER BY COUNTRY_CODE;
SELECT * FROM VALID_STATUSES ORDER BY STATUS_CODE;


-- =================================================================
--  STEP 3: CREATE THE DATA TABLES
-- =================================================================

-- RAW table: Where incoming data lands (messy, unchecked)
USE SCHEMA RAW;

CREATE OR REPLACE TABLE CUSTOMER_ORDERS (
    ROW_ID          NUMBER AUTOINCREMENT,
    CUSTOMER_NAME   VARCHAR(200),
    EMAIL           VARCHAR(500),
    PHONE           VARCHAR(50),
    COUNTRY_CODE    VARCHAR(5),
    ORDER_ID        NUMBER,
    ORDER_DATE      DATE,
    ORDER_AMOUNT    NUMBER(12,2),
    ORDER_STATUS    VARCHAR(20),
    LOADED_AT       TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- CLEAN table: Only validated data ends up here
USE SCHEMA CLEAN;

CREATE OR REPLACE TABLE CUSTOMER_ORDERS (
    ROW_ID          NUMBER,
    CUSTOMER_NAME   VARCHAR(200),
    EMAIL           VARCHAR(500),
    PHONE           VARCHAR(50),
    COUNTRY_CODE    VARCHAR(5),
    ORDER_ID        NUMBER,
    ORDER_DATE      DATE,
    ORDER_AMOUNT    NUMBER(12,2),
    ORDER_STATUS    VARCHAR(20),
    VALIDATED_AT    TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- ERROR table: Failed records with explanations
USE SCHEMA ERRORS;

CREATE OR REPLACE TABLE FAILED_RECORDS (
    ERROR_ID        NUMBER AUTOINCREMENT,
    ROW_ID          NUMBER,
    CUSTOMER_NAME   VARCHAR(200),
    ORDER_ID        NUMBER,
    FAILED_CHECK    VARCHAR(200),
    FAILED_COLUMN   VARCHAR(100),
    ACTUAL_VALUE    VARCHAR(500),
    ERROR_MESSAGE   VARCHAR(500),
    SEVERITY        VARCHAR(20),
    FULL_RECORD     VARIANT,
    CHECKED_AT      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- LOG table: Track each validation run
CREATE OR REPLACE TABLE VALIDATION_LOG (
    LOG_ID          NUMBER AUTOINCREMENT,
    RUN_TIMESTAMP   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    TOTAL_RECORDS   NUMBER,
    PASSED          NUMBER,
    FAILED          NUMBER,
    STATUS          VARCHAR(20)
);


-- =================================================================
--  STEP 4: LOAD SAMPLE DATA (Mix of good and bad)
--  
--  12 records with various problems for our procedure to catch.
-- =================================================================

USE SCHEMA RAW;

INSERT INTO CUSTOMER_ORDERS 
    (CUSTOMER_NAME, EMAIL, PHONE, COUNTRY_CODE, ORDER_ID, ORDER_DATE, ORDER_AMOUNT, ORDER_STATUS)
VALUES
    -- GOOD RECORDS (should pass)
    ('Alice Johnson',  'alice@email.com',     '+1-555-0101', 'US', 3001, '2025-06-15', 1250.00, 'NEW'),
    ('Bob Williams',   'bob@company.co.uk',   '+44-20-7946',  'UK', 3002, '2025-07-20', 3400.50, 'SHIPPED'),
    ('Sakura Tanaka',  'sakura@mail.jp',      '+81-3-1234',  'JP', 3003, '2025-08-01',  780.25, 'PROCESSING'),
    ('Carlos Garcia',  'carlos@firma.de',     '+49-30-5678', 'DE', 3004, '2025-05-10', 2100.00, 'DELIVERED'),

    -- BAD: NULL customer name
    (NULL,             'ghost@email.com',     '+1-555-0000', 'US', 3005, '2025-06-01',  500.00, 'NEW'),

    -- BAD: Invalid email format (no @ sign)
    ('Dave Wilson',    'dave-at-email.com',   '+1-555-0202', 'CA', 3006, '2025-07-15',  320.00, 'NEW'),

    -- BAD: Invalid country code (ZZ doesn't exist)
    ('Eve Brown',      'eve@email.com',       '+1-555-0303', 'ZZ', 3007, '2025-08-10',  890.00, 'SHIPPED'),

    -- BAD: Future date
    ('Frank Lee',      'frank@email.com',     '+1-555-0404', 'US', 3008, '2029-12-31', 1500.00, 'NEW'),

    -- BAD: Negative amount
    ('Grace Kim',      'grace@email.com',     '+1-555-0505', 'JP', 3009, '2025-03-20', -200.00, 'PROCESSING'),

    -- BAD: Invalid order status
    ('Henry Park',     'henry@email.com',     '+1-555-0606', 'AU', 3010, '2025-04-15',  650.00, 'MAGIC_STATUS'),

    -- BAD: Duplicate order ID (same as row 1)
    ('Ivy Chen',       'ivy@email.com',       '+1-555-0707', 'US', 3001, '2025-09-01',  440.00, 'NEW'),

    -- BAD: Name is "TEST" (placeholder)
    ('TEST',           'test@email.com',      '+1-555-0808', 'CA', 3012, '2025-05-25',  100.00, 'NEW');

-- Look at all our raw data
SELECT ROW_ID, CUSTOMER_NAME, EMAIL, COUNTRY_CODE, ORDER_ID, 
       ORDER_AMOUNT, ORDER_STATUS
FROM RAW.CUSTOMER_ORDERS 
ORDER BY ROW_ID;


-- =================================================================
--  STEP 5: THE STORED PROCEDURE
--  
--  A stored procedure is a SAVED PROGRAM inside Snowflake.
--  Instead of running 10 separate queries, you run ONE command
--  and it does everything automatically.
--  
--  NEW CONCEPTS IN THIS PROCEDURE:
--  
--  1. DECLARE / BEGIN / END
--     This is the structure of a Snowflake Scripting procedure.
--     DECLARE = create variables
--     BEGIN   = start the logic
--     END     = finish
--  
--  2. Variables (LET v_total := ...)
--     Like a box that holds a value. You can use it later.
--     Example: v_total holds the count of all records.
--  
--  3. REGEXP_LIKE(column, pattern)
--     Checks if text matches a pattern.
--     Pattern: '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'
--     In English: "letters/numbers, then @, then letters, then .com/.org/etc."
--     
--  4. OBJECT_CONSTRUCT('key', value, 'key', value)
--     Builds a JSON object from your columns. Like packing
--     all the columns into one neat package.
--     Result: {"NAME": "Alice", "EMAIL": "alice@email.com", ...}
--  
--  5. IFF(condition, true_value, false_value)
--     Shorter version of CASE WHEN. 
--     IFF(AGE > 18, 'Adult', 'Minor') = if age>18 then 'Adult' else 'Minor'
--  
--  6. RETURN 'some text'
--     What the procedure gives back when it's done.
--     Like a function in math: f(x) = x + 1 RETURNS a number.
-- =================================================================

CREATE OR REPLACE PROCEDURE ERRORS.VALIDATE_CUSTOMER_ORDERS()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
DECLARE
    v_total         NUMBER DEFAULT 0;
    v_failed_count  NUMBER DEFAULT 0;
    v_passed_count  NUMBER DEFAULT 0;
BEGIN

    -- ===== PREPARATION: Count records and clear previous results =====
    SELECT COUNT(*) INTO v_total FROM RAW.CUSTOMER_ORDERS;
    TRUNCATE TABLE IF EXISTS CLEAN.CUSTOMER_ORDERS;
    TRUNCATE TABLE IF EXISTS ERRORS.FAILED_RECORDS;


    -- ===== CHECK 1: NULL Customer Name =====
    -- Find rows where customer name is empty
    INSERT INTO ERRORS.FAILED_RECORDS 
        (ROW_ID, CUSTOMER_NAME, ORDER_ID, FAILED_CHECK, FAILED_COLUMN, 
         ACTUAL_VALUE, ERROR_MESSAGE, SEVERITY, FULL_RECORD)
    SELECT 
        ROW_ID,
        CUSTOMER_NAME,
        ORDER_ID,
        'NULL_CHECK',
        'CUSTOMER_NAME',
        'NULL',
        'Customer Name is required and cannot be empty',
        'ERROR',
        OBJECT_CONSTRUCT(
            'CUSTOMER_NAME', CUSTOMER_NAME, 'EMAIL', EMAIL,
            'ORDER_ID', ORDER_ID, 'ORDER_AMOUNT', ORDER_AMOUNT
        )
    FROM RAW.CUSTOMER_ORDERS
    WHERE CUSTOMER_NAME IS NULL;


    -- ===== CHECK 2: Email Format =====
    -- Use REGEXP_LIKE to check if email looks like "user@domain.com"
    INSERT INTO ERRORS.FAILED_RECORDS 
        (ROW_ID, CUSTOMER_NAME, ORDER_ID, FAILED_CHECK, FAILED_COLUMN,
         ACTUAL_VALUE, ERROR_MESSAGE, SEVERITY, FULL_RECORD)
    SELECT 
        ROW_ID,
        CUSTOMER_NAME,
        ORDER_ID,
        'PATTERN_CHECK',
        'EMAIL',
        EMAIL,
        'Email format is invalid (expected: user@domain.com)',
        'ERROR',
        OBJECT_CONSTRUCT(
            'CUSTOMER_NAME', CUSTOMER_NAME, 'EMAIL', EMAIL,
            'ORDER_ID', ORDER_ID, 'ORDER_AMOUNT', ORDER_AMOUNT
        )
    FROM RAW.CUSTOMER_ORDERS
    WHERE EMAIL IS NOT NULL
      AND NOT REGEXP_LIKE(EMAIL, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$');


    -- ===== CHECK 3: Valid Country Code =====
    -- Country must exist in our lookup table
    INSERT INTO ERRORS.FAILED_RECORDS
        (ROW_ID, CUSTOMER_NAME, ORDER_ID, FAILED_CHECK, FAILED_COLUMN,
         ACTUAL_VALUE, ERROR_MESSAGE, SEVERITY, FULL_RECORD)
    SELECT 
        ROW_ID,
        CUSTOMER_NAME,
        ORDER_ID,
        'REFERENTIAL_CHECK',
        'COUNTRY_CODE',
        COUNTRY_CODE,
        'Country code "' || COUNTRY_CODE || '" does not exist in approved list',
        'ERROR',
        OBJECT_CONSTRUCT(
            'CUSTOMER_NAME', CUSTOMER_NAME, 'EMAIL', EMAIL,
            'COUNTRY_CODE', COUNTRY_CODE, 'ORDER_ID', ORDER_ID
        )
    FROM RAW.CUSTOMER_ORDERS
    WHERE COUNTRY_CODE IS NOT NULL
      AND COUNTRY_CODE NOT IN (SELECT COUNTRY_CODE FROM LOOKUPS.VALID_COUNTRIES);


    -- ===== CHECK 4: Valid Order Status =====
    INSERT INTO ERRORS.FAILED_RECORDS
        (ROW_ID, CUSTOMER_NAME, ORDER_ID, FAILED_CHECK, FAILED_COLUMN,
         ACTUAL_VALUE, ERROR_MESSAGE, SEVERITY, FULL_RECORD)
    SELECT 
        ROW_ID,
        CUSTOMER_NAME,
        ORDER_ID,
        'REFERENTIAL_CHECK',
        'ORDER_STATUS',
        ORDER_STATUS,
        'Order status "' || ORDER_STATUS || '" is not a valid status',
        'ERROR',
        OBJECT_CONSTRUCT(
            'CUSTOMER_NAME', CUSTOMER_NAME, 'ORDER_STATUS', ORDER_STATUS,
            'ORDER_ID', ORDER_ID
        )
    FROM RAW.CUSTOMER_ORDERS
    WHERE ORDER_STATUS IS NOT NULL
      AND ORDER_STATUS NOT IN (SELECT STATUS_CODE FROM LOOKUPS.VALID_STATUSES);


    -- ===== CHECK 5: Order Date Not in Future =====
    INSERT INTO ERRORS.FAILED_RECORDS
        (ROW_ID, CUSTOMER_NAME, ORDER_ID, FAILED_CHECK, FAILED_COLUMN,
         ACTUAL_VALUE, ERROR_MESSAGE, SEVERITY, FULL_RECORD)
    SELECT 
        ROW_ID,
        CUSTOMER_NAME,
        ORDER_ID,
        'DATE_CHECK',
        'ORDER_DATE',
        TO_VARCHAR(ORDER_DATE),
        'Order date ' || TO_VARCHAR(ORDER_DATE) || ' is in the future',
        'ERROR',
        OBJECT_CONSTRUCT(
            'CUSTOMER_NAME', CUSTOMER_NAME, 'ORDER_DATE', ORDER_DATE,
            'ORDER_ID', ORDER_ID
        )
    FROM RAW.CUSTOMER_ORDERS
    WHERE ORDER_DATE > CURRENT_DATE();


    -- ===== CHECK 6: Order Amount Must Be Positive =====
    INSERT INTO ERRORS.FAILED_RECORDS
        (ROW_ID, CUSTOMER_NAME, ORDER_ID, FAILED_CHECK, FAILED_COLUMN,
         ACTUAL_VALUE, ERROR_MESSAGE, SEVERITY, FULL_RECORD)
    SELECT 
        ROW_ID,
        CUSTOMER_NAME,
        ORDER_ID,
        'RANGE_CHECK',
        'ORDER_AMOUNT',
        TO_VARCHAR(ORDER_AMOUNT),
        'Order amount $' || TO_VARCHAR(ORDER_AMOUNT) || ' must be greater than zero',
        'ERROR',
        OBJECT_CONSTRUCT(
            'CUSTOMER_NAME', CUSTOMER_NAME, 'ORDER_AMOUNT', ORDER_AMOUNT,
            'ORDER_ID', ORDER_ID
        )
    FROM RAW.CUSTOMER_ORDERS
    WHERE ORDER_AMOUNT <= 0;


    -- ===== CHECK 7: Duplicate Order IDs =====
    INSERT INTO ERRORS.FAILED_RECORDS
        (ROW_ID, CUSTOMER_NAME, ORDER_ID, FAILED_CHECK, FAILED_COLUMN,
         ACTUAL_VALUE, ERROR_MESSAGE, SEVERITY, FULL_RECORD)
    SELECT 
        ROW_ID,
        CUSTOMER_NAME,
        ORDER_ID,
        'UNIQUENESS_CHECK',
        'ORDER_ID',
        TO_VARCHAR(ORDER_ID),
        'Duplicate Order ID ' || TO_VARCHAR(ORDER_ID) || ' found',
        'ERROR',
        OBJECT_CONSTRUCT(
            'CUSTOMER_NAME', CUSTOMER_NAME, 'ORDER_ID', ORDER_ID,
            'ORDER_AMOUNT', ORDER_AMOUNT
        )
    FROM RAW.CUSTOMER_ORDERS
    WHERE ORDER_ID IN (
        SELECT ORDER_ID FROM RAW.CUSTOMER_ORDERS
        GROUP BY ORDER_ID HAVING COUNT(*) > 1
    );


    -- ===== CHECK 8: Placeholder Names =====
    -- Names like "TEST", "DUMMY", "N/A" are probably not real
    INSERT INTO ERRORS.FAILED_RECORDS
        (ROW_ID, CUSTOMER_NAME, ORDER_ID, FAILED_CHECK, FAILED_COLUMN,
         ACTUAL_VALUE, ERROR_MESSAGE, SEVERITY, FULL_RECORD)
    SELECT 
        ROW_ID,
        CUSTOMER_NAME,
        ORDER_ID,
        'CUSTOM_CHECK',
        'CUSTOMER_NAME',
        CUSTOMER_NAME,
        'Customer name "' || CUSTOMER_NAME || '" looks like a placeholder',
        'WARNING',
        OBJECT_CONSTRUCT(
            'CUSTOMER_NAME', CUSTOMER_NAME, 'ORDER_ID', ORDER_ID
        )
    FROM RAW.CUSTOMER_ORDERS
    WHERE UPPER(CUSTOMER_NAME) IN ('TEST', 'DUMMY', 'N/A', 'TBD', 'UNKNOWN', 'NULL');


    -- ===== MOVE CLEAN RECORDS =====
    -- Insert rows that have ZERO errors (ERROR severity only)
    -- WARNING-only rows are allowed through
    INSERT INTO CLEAN.CUSTOMER_ORDERS
        (ROW_ID, CUSTOMER_NAME, EMAIL, PHONE, COUNTRY_CODE,
         ORDER_ID, ORDER_DATE, ORDER_AMOUNT, ORDER_STATUS)
    SELECT 
        ROW_ID, CUSTOMER_NAME, EMAIL, PHONE, COUNTRY_CODE,
        ORDER_ID, ORDER_DATE, ORDER_AMOUNT, ORDER_STATUS
    FROM RAW.CUSTOMER_ORDERS
    WHERE ROW_ID NOT IN (
        SELECT DISTINCT ROW_ID FROM ERRORS.FAILED_RECORDS WHERE SEVERITY = 'ERROR'
    );


    -- ===== COUNT RESULTS =====
    SELECT COUNT(*) INTO v_passed_count FROM CLEAN.CUSTOMER_ORDERS;
    SELECT COUNT(DISTINCT ROW_ID) INTO v_failed_count 
    FROM ERRORS.FAILED_RECORDS WHERE SEVERITY = 'ERROR';


    -- ===== LOG THE RUN =====
    INSERT INTO ERRORS.VALIDATION_LOG (TOTAL_RECORDS, PASSED, FAILED, STATUS)
    VALUES (
        :v_total,
        :v_passed_count,
        :v_failed_count,
        IFF(:v_failed_count = 0, 'ALL_PASSED', IFF(:v_passed_count = 0, 'ALL_FAILED', 'PARTIAL'))
    );


    -- ===== RETURN SUMMARY =====
    RETURN 'Validation Complete | Total: ' || v_total 
        || ' | Passed: ' || v_passed_count 
        || ' | Failed: ' || v_failed_count
        || ' | Pass Rate: ' || ROUND(v_passed_count * 100.0 / NULLIF(v_total, 0), 1) || '%';

END;
$$;


-- =================================================================
--  STEP 6: RUN THE VALIDATION
--  
--  One command does everything! This is the power of a procedure.
-- =================================================================

CALL ERRORS.VALIDATE_CUSTOMER_ORDERS();


-- =================================================================
--  STEP 7: EXAMINE THE RESULTS
-- =================================================================

-- 7a: Clean records (those that passed)
SELECT '--- CLEAN RECORDS ---' AS SECTION;
SELECT ROW_ID, CUSTOMER_NAME, EMAIL, ORDER_ID, ORDER_AMOUNT, ORDER_STATUS
FROM CLEAN.CUSTOMER_ORDERS
ORDER BY ROW_ID;

-- 7b: Failed records with error details
SELECT '--- FAILED RECORDS WITH DETAILS ---' AS SECTION;
SELECT 
    ROW_ID,
    CUSTOMER_NAME,
    ORDER_ID,
    FAILED_CHECK,
    FAILED_COLUMN,
    ACTUAL_VALUE,
    ERROR_MESSAGE,
    SEVERITY
FROM ERRORS.FAILED_RECORDS
ORDER BY ROW_ID, FAILED_CHECK;

-- 7c: See the original record saved as JSON
SELECT '--- FULL RECORD AS JSON ---' AS SECTION;
SELECT 
    ROW_ID, 
    FAILED_CHECK,
    FULL_RECORD
FROM ERRORS.FAILED_RECORDS
WHERE SEVERITY = 'ERROR'
LIMIT 5;

-- 7d: Error summary (which checks caught the most issues?)
SELECT '--- ERROR SUMMARY BY CHECK TYPE ---' AS SECTION;
SELECT 
    FAILED_CHECK,
    SEVERITY,
    COUNT(*) AS HOW_MANY_CAUGHT
FROM ERRORS.FAILED_RECORDS
GROUP BY FAILED_CHECK, SEVERITY
ORDER BY HOW_MANY_CAUGHT DESC;

-- 7e: Validation run log
SELECT '--- VALIDATION LOG ---' AS SECTION;
SELECT * FROM ERRORS.VALIDATION_LOG;

-- 7f: Data quality scorecard
SELECT '--- SCORECARD ---' AS SECTION;
SELECT 
    TOTAL_RECORDS,
    PASSED,
    FAILED,
    ROUND(PASSED * 100.0 / NULLIF(TOTAL_RECORDS, 0), 1) AS PASS_RATE_PCT,
    STATUS
FROM ERRORS.VALIDATION_LOG
ORDER BY LOG_ID DESC LIMIT 1;


-- =================================================================
--  STEP 8: CLEANUP (Optional)
-- =================================================================

-- Uncomment to delete everything:
-- DROP DATABASE IF EXISTS DQ_INTERMEDIATE_LAB;


-- =================================================================
--  WHAT YOU LEARNED (NEW compared to Beginner):
--  
--  1. Stored Procedure  - A saved program: CREATE PROCEDURE / CALL
--  2. Variables          - DECLARE v_total NUMBER; ... := value
--  3. REGEXP_LIKE()     - Pattern matching for formats (email)
--  4. Lookup Tables     - Reference lists for valid values
--  5. NOT IN (subquery) - "This value is NOT in that list"
--  6. OBJECT_CONSTRUCT  - Build JSON from column values
--  7. IFF()             - Short if-then-else: IFF(cond, yes, no)
--  8. Multiple Schemas  - Organizing tables into folders
--  9. TRUNCATE          - Fast way to delete all rows from a table
--  10. Validation Log   - Tracking each run with counts and status
--  
--  HOW THIS COMPARES TO THE FULL FRAMEWORK:
--  
--  This File (Intermediate)       | Full Framework (Advanced)
--  -------------------------------|----------------------------------
--  8 checks hardcoded in SQL      | Rules stored in a config TABLE
--  Works with 1 specific table    | Works with ANY table (dynamic)
--  No cursor/loop                 | Cursor loops through rules
--  No dynamic SQL                 | EXECUTE IMMEDIATE builds SQL
--  Manual execution               | Automated via Streams + Tasks
--  Simple text return             | Structured VARIANT/JSON return
--  Basic error log                | Full monitoring with 6 views
--  
--  NEXT STEP: You're ready for the full framework!
--  Open 03_create_validation_engine.sql and
--  read CODE_WALKTHROUGH.md side by side.
-- =================================================================
