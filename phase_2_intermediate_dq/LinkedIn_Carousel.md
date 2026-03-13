# LinkedIn Carousel — Phase 2: From Manual Checks to One-Click Validation

---

## Slide 1 — Hook

**Phase 2: One CALL to Validate Them All**

From 5 manual SQL queries → 1 stored procedure

Snowflake Data Validation Gateway

---

## Slide 2 — The Problem

Phase 1: Manual Data Quality

▸ Run 5 separate SQL queries
▸ Each check is independent
▸ Easy to miss a step
▸ No audit trail
▸ No routing of clean vs failed data

---

## Slide 3 — The Solution

Phase 2: Stored Procedure

CALL VALIDATE_CUSTOMER_ORDERS();

▸ One command runs ALL 8 checks
▸ Clean data → CLEAN schema
▸ Failed data → ERRORS schema
▸ Every run logged with timestamps

---

## Slide 4 — What the Procedure Does

8 validation checks in one CALL:

1. NULL checks (required fields)
2. Email format (REGEXP_LIKE)
3. Country lookup (referential integrity)
4. Status lookup (valid values)
5. Future date detection
6. Negative amount check
7. Duplicate order ID detection
8. Placeholder name detection (TEST, N/A)

---

## Slide 5 — Key SQL Concepts

▸ CREATE PROCEDURE → Encapsulate logic
▸ REGEXP_LIKE → Pattern matching
▸ OBJECT_CONSTRUCT → Capture full record as JSON
▸ IFF() → Concise conditional logic
▸ LET → Variables in Snowflake scripting
▸ Multi-schema design → RAW, CLEAN, ERRORS, LOOKUPS

---

## Slide 6 — Architecture

```
RAW.CUSTOMER_ORDERS
        │
        ▼
  CALL VALIDATE_CUSTOMER_ORDERS()
        │
   ┌────┴────┐
   ▼         ▼
 CLEAN    ERRORS
 (pass)   (fail + JSON record)
              │
              ▼
        VALIDATION_LOG
        (audit trail)
```

---

## Slide 7 — Phase 1 vs Phase 2

| Phase 1 | Phase 2 |
|---------|---------|
| Manual queries | One CALL |
| WHERE filters | REGEXP_LIKE |
| Text errors | JSON records |
| Single schema | Multi-schema |
| No logging | Timestamped audit |

---

## Slide 8 — What's Next

Phase 3: Configuration-Driven Validation

▸ Rules move to a CONFIG table
▸ Add rules with INSERT, not code changes
▸ Dynamic SQL reads rules at runtime
▸ Zero redeployment

---

## Slide 9 — CTA

Try it yourself:
https://github.com/Techy-Malay/snowflake-data-validation-gateway

Follow for more Snowflake architecture content

Malaya Kumar Padhi
Senior Solution Architect — Data & AI Platforms
https://www.linkedin.com/in/mkpadhi/

---

**Author:** [Malaya Kumar Padhi](https://www.linkedin.com/in/mkpadhi/) | Senior Solution Architect — Data & AI Platforms  
*Part of the [Snowflake Data Validation Gateway](https://github.com/Techy-Malay/snowflake-data-validation-gateway) series.*
