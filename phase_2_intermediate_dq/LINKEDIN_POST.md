Phase 2: From Manual Checks to One-Click Validation
In Phase 1, I ran 5 separate SQL queries to check data quality.
It worked. But it was manual. Repetitive. Error-prone.

Phase 2 question: What if ONE command did all of that?
─────────────────
The answer: a Stored Procedure.
CALL VALIDATE_CUSTOMER_ORDERS();
One command. All checks run. Clean data routed to CLEAN schema. Bad data quarantined to ERRORS schema. Every error logged with a timestamp.
─────────────────
What I added in Phase 2:
▸ Stored Procedure → Run ALL validations with a single CALL
▸ REGEXP_LIKE → Pattern match emails, phone numbers, formats
▸ OBJECT_CONSTRUCT → Capture the entire failed record as JSON
▸ Lookup Tables → Validate foreign keys against reference data
▸ Error Logging → Every run logged with timestamp and pass/fail counts
▸ Multi-Schema → RAW → CLEAN / ERRORS (architectural separation)
─────────────────
The Architecture Shift:
Phase 1: You run 5 queries manually
Phase 2: You run 1 CALL → procedure runs 8 checks → routes results automatically

Same checks. Completely different workflow.

─────────────────
The key insight:
Phase 1 taught me WHAT to check.
Phase 2 taught me HOW to automate it.

But the rules are still hardcoded inside the procedure. Want to add a new check? Edit the code. Redeploy.

Phase 3 fixes this → rules move to a configuration table. The engine reads them at runtime. Add a rule with an INSERT. No code changes.
─────────────────
Try It:

Full SQL file in my GitHub repo:
https://github.com/Techy-Malay/snowflake-data-validation-gateway

30 minutes. One stored procedure. A real validation system.

─────────────────
Tech: Snowflake | SQL | Stored Procedures | Data Quality
What's your take? Drop a comment ↓

#Snowflake #DataQuality #StoredProcedures #DataEngineering #SQL #LearningInPublic #DataArchitecture

─────────────────

Author: Malaya Kumar Padhi | Senior Solution Architect — Data & AI Platforms
https://www.linkedin.com/in/mkpadhi/
