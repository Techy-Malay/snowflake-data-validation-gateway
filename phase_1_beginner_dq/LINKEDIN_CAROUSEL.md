# Phase 1: LinkedIn Carousel — My First Data Quality Check

> Convert each slide below into a PDF page using Canva, Gamma, or Google Slides.
> Each slide = one swipeable page on LinkedIn.

---

## Slide 1 — Hook

**My First Data Quality Check on Snowflake**

6 SQL concepts. 15 minutes. Zero tools.

*Swipe to learn the pattern →*

---

## Slide 2 — The Problem

**Bad data costs $12.9M/year** (Gartner)

→ NULL values break dashboards
→ Duplicates inflate metrics
→ Future dates corrupt reports

You don't need an enterprise tool to fix this.

---

## Slide 3 — The 6 SQL Concepts

▸ IS NULL — Find missing values
▸ WHERE amount <= 0 — Check ranges
▸ CURRENT_DATE() — Detect future dates
▸ GROUP BY / HAVING — Find duplicates
▸ CASE WHEN — Build a report card
▸ CREATE TABLE AS — Separate clean from bad

---

## Slide 4 — The Data

8 sample records:
→ 2 perfect records
→ 1 missing customer name
→ 1 missing email + negative amount
→ 1 future date (2029!)
→ 1 duplicate order ID
→ 1 zero amount
→ 1 perfect record

---

## Slide 5 — The Architecture

```
[ORDERS_RAW] → [5 SQL Checks] → [ORDERS_CLEAN]
                     ↓
               [ORDERS_ERRORS]
```

YOU are the engine. Each check is a manual query.

---

## Slide 6 — The Results

TOTAL: 8 records
CLEAN: 2 records (passed ALL checks)
ERRORS: 6 records (failed one or more)

Every violation caught. Every error documented.

---

## Slide 7 — The Core Pattern

Every DQ system follows the same pattern:

RAW → CHECK → CLEAN / REJECT

Phase 1 = this pattern with plain SQL
Phase 2 = automate with Stored Procedures
Phase 3 = metadata-driven engine

---

## Slide 8 — Try It Yourself

Full SQL file on GitHub:
github.com/Techy-Malay/snowflake-data-validation-gateway

15 minutes. One SQL file. Zero setup.

Follow for Phase 2 →

---

**Author:** [Malaya Kumar Padhi](https://www.linkedin.com/in/mkpadhi/) | Senior Solution Architect — Data & AI Platforms
*Part of the [Snowflake Data Validation Gateway](https://github.com/Techy-Malay/snowflake-data-validation-gateway) series.*
