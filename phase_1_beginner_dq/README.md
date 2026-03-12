# Phase 1 — My First Data Quality Check

**Level:** Beginner | **Time:** 15-20 minutes | **Complexity:** Plain SQL only

[![Snowflake](https://img.shields.io/badge/Platform-Snowflake-29B5E8?logo=snowflake&logoColor=white)](https://www.snowflake.com/)
[![SQL](https://img.shields.io/badge/Language-SQL-blue)](https://docs.snowflake.com/en/sql-reference.html)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../../LICENSE)

---

## Goal

Understand what Data Quality (DQ) is and run your first validation checks using nothing but basic SQL.

No stored procedures. No dynamic SQL. No cursors. Just `SELECT`, `CASE WHEN`, and `WHERE`.

---

## What You Will Learn

| # | Concept | SQL Used |
|---|---------|----------|
| 1 | Find missing values | `IS NULL` |
| 2 | Check value ranges | `WHERE amount <= 0` |
| 3 | Detect future dates | `CURRENT_DATE()` |
| 4 | Find duplicates | `GROUP BY / HAVING COUNT(*) > 1` |
| 5 | Build a report card | `CASE WHEN ... THEN ... END` |
| 6 | Separate good from bad | `CREATE TABLE AS SELECT` |

---

## Architecture

### Mermaid: High-Level Data Flow

```mermaid
flowchart LR
    A[("ORDERS_RAW\n8 records\n(mix of good & bad)")] --> B{"Manual SQL Checks\n(YOU are the engine)"}
    B -->|"PASS all checks"| C[("ORDERS_CLEAN\n2 records")]
    B -->|"FAIL any check"| D[("ORDERS_ERRORS\n6 records\n+ ERROR_REASON")]

    style A fill:#4A90D9,stroke:#333,color:#fff
    style B fill:#F5A623,stroke:#333,color:#fff
    style C fill:#7ED321,stroke:#333,color:#fff
    style D fill:#D0021B,stroke:#333,color:#fff
```

### Mermaid: Step-by-Step Validation Flow

```mermaid
flowchart TD
    START["Step 1-3: Setup\nCreate DB, Table, Insert 8 rows"] --> CHECK1

    subgraph CHECKS ["Steps 4-8: Individual DQ Checks"]
        CHECK1["Check 1: NULL Name\nIS NULL"] --> CHECK2["Check 2: NULL Email\nIS NULL"]
        CHECK2 --> CHECK3["Check 3: Invalid Amount\nORDER_AMOUNT <= 0"]
        CHECK3 --> CHECK4["Check 4: Future Date\nORDER_DATE > CURRENT_DATE()"]
        CHECK4 --> CHECK5["Check 5: Duplicate Order ID\nGROUP BY + HAVING"]
    end

    CHECKS --> COMBINE["Step 9: Combined Report Card\nCASE WHEN (all checks in one query)"]
    COMBINE --> SEPARATE["Step 10: Separate Data\nCREATE TABLE AS SELECT"]

    SEPARATE --> CLEAN["ORDERS_CLEAN\nBob Jones, Henry Park"]
    SEPARATE --> ERRORS["ORDERS_ERRORS\n6 rows + ERROR_REASON + CHECKED_AT"]

    CLEAN --> RESULTS["Step 11: View Results\nTOTAL: 8 | CLEAN: 2 | ERRORS: 6"]
    ERRORS --> RESULTS

    style START fill:#4A90D9,stroke:#333,color:#fff
    style CHECKS fill:#f0f0f0,stroke:#999
    style COMBINE fill:#F5A623,stroke:#333,color:#fff
    style SEPARATE fill:#9B59B6,stroke:#333,color:#fff
    style CLEAN fill:#7ED321,stroke:#333,color:#fff
    style ERRORS fill:#D0021B,stroke:#333,color:#fff
    style RESULTS fill:#34495E,stroke:#333,color:#fff
```

### Mermaid: What Each Check Catches

```mermaid
flowchart LR
    subgraph INPUT ["8 Raw Records"]
        R1["Row 1: Alice - OK"]
        R2["Row 2: Bob - OK"]
        R3["Row 3: NULL name"]
        R4["Row 4: NULL email + negative amount"]
        R5["Row 5: Future date 2029"]
        R6["Row 6: Duplicate ID 101"]
        R7["Row 7: Zero amount"]
        R8["Row 8: Henry - OK"]
    end

    R1 -->|"Dup ID 101"| ERRORS
    R2 -->|"All PASS"| CLEAN
    R3 -->|"NULL name"| ERRORS
    R4 -->|"NULL email + amount"| ERRORS
    R5 -->|"Future date"| ERRORS
    R6 -->|"Dup ID 101"| ERRORS
    R7 -->|"Zero amount"| ERRORS
    R8 -->|"All PASS"| CLEAN

    CLEAN["ORDERS_CLEAN (2)"]
    ERRORS["ORDERS_ERRORS (6)"]

    style CLEAN fill:#7ED321,stroke:#333,color:#fff
    style ERRORS fill:#D0021B,stroke:#333,color:#fff
```

### ASCII Fallback (for terminals/Snowsight)

```
+-------------------------------------------------------+
|              PHASE 1 — BEGINNER DQ                     |
+-------------------------------------------------------+
|                                                       |
|  [ORDERS_RAW]                                         |
|       |                                               |
|       |--- SELECT WHERE (check each rule)             |
|       |                                               |
|       +---> [ORDERS_CLEAN]   (rows that PASSED)       |
|       |                                               |
|       +---> [ORDERS_ERRORS]  (rows that FAILED)       |
|                                                       |
|  Checks: NULL, Range, Date, Duplicates                |
|  Method: Manual SQL queries (CASE WHEN)               |
|  Automation: NONE (you run each query by hand)        |
+-------------------------------------------------------+
```

**Key idea:** You are the engine. You write each check manually.

---

## Prerequisites

- Snowflake account (any edition)
- Basic SQL: `SELECT`, `INSERT`, `CREATE TABLE`
- Any role with `CREATE DATABASE` privilege

---

## Repository Structure

```
phase_1_beginner_dq/
|-- sql/
|   |-- DQ_LEVEL_1_BEGINNER.sql   # Complete SQL file (run top to bottom)
|-- doc/
|-- README.md                      # This file
|-- LINKEDIN_POST.md               # Ready-to-publish LinkedIn content
|-- LINKEDIN_CAROUSEL.md           # Slide-by-slide carousel content
```

---

## Quick Start

1. Open `phase_1_beginner_dq/sql/DQ_LEVEL_1_BEGINNER.sql` in Snowsight
2. Run Steps 1-3 (boilerplate: database, table, sample data)
3. Run Steps 4-8 one at a time (individual DQ checks)
4. Run Step 9 (combined report card)
5. Run Steps 10-11 (separate clean/error data, view results)

---

## Cleanup

```sql
-- Uncomment and run when done:
-- DROP DATABASE IF EXISTS DQ_BEGINNER_LAB;
```

---

## What's Next

After completing Phase 1, you'll understand the core DQ pattern: **check → separate → report**.

**Phase 2** takes this further by wrapping all checks into a Stored Procedure that runs automatically with one command.

---

## License

This project is licensed under the MIT License — see the [LICENSE](../../LICENSE) file.

---

## Author

**Malaya Kumar Padhi**
Senior Solution Architect | Data & AI Platforms

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/mkpadhi/)
[![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/Techy-Malay/snowflake-data-validation-gateway)

---

`#Snowflake` `#DataQuality` `#SQL` `#DataEngineering`
