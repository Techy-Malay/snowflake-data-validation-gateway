# Phase 1: My First Data Quality Check — Plain SQL Approach

> LinkedIn post content below. Copy the text between the `---` markers.
> LinkedIn does NOT support markdown — use Unicode symbols and line breaks only.

---

I built my first Data Quality check on Snowflake

Using nothing but 6 basic SQL concepts ↓

─────────────────

You don't need fancy tools to start checking data quality.

You need:

▸ IS NULL → Find missing values
▸ WHERE amount<=0 → Check value ranges
▸ CURRENT_DATE() → Detect impossible dates
▸ GROUP BY/HAVING → Find duplicates
▸ CASE WHEN → Build a pass/fail report card
▸ CREATE TABLE AS → Separate clean data from bad data

That's it. No stored procedures. No frameworks. No external tools.

─────────────────

Here's what I built in 15 minutes:

8 rows of sample data. 5 data quality checks. 1 clear outcome.

TOTAL: 8 records
CLEAN: 2 records (passed ALL checks)
ERRORS: 6 records (failed one or more checks)

The checks caught:
→ Missing customer names (NULL)
→ Missing emails
→ Negative order amounts
→ Future dates (year 2029!)
→ Duplicate order IDs

All with plain SQL. No magic.

─────────────────

THE PATTERN

Every data quality system follows the same core pattern:

Raw Data → Check Rules → Clean Data
                 ↓
            Error Data

Phase 1 teaches this pattern with the simplest tools available.

─────────────────

WHY THIS MATTERS

Bad data costs organizations $12.9M per year (Gartner).

But you don't need to buy a tool to start fixing it.
You need to understand the pattern.
And the pattern starts with a CASE WHEN.

─────────────────

Try it yourself — full SQL file on GitHub:
https://github.com/Techy-Malay/snowflake-data-validation-gateway

Run it in Snowsight. Takes 15 minutes. Zero setup beyond a Snowflake account.

Next up: Phase 2 → wrapping all these manual checks into a single Stored Procedure that runs with one command.

What's your take? Drop a comment ↓

#Snowflake #DataQuality #SQL #DataEngineering #DataArchitecture #LearningInPublic

---

**Author:** [Malaya Kumar Padhi](https://www.linkedin.com/in/mkpadhi/) | Senior Solution Architect — Data & AI Platforms
*Part of the [Snowflake Data Validation Gateway](https://github.com/Techy-Malay/snowflake-data-validation-gateway) series.*
