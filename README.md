Environment & Versions
- SQL: Compatible with MySQL 8.0 / PostgreSQL 13+
- R: Tested on R 4.2.2
- R Packages: `dplyr`, `tidyverse`, `data.table`
- Data struture: OMOP CDM

## SQL Query Overview
This SQL script processes vaccine data and associated health conditions. Key steps:

1. **Extract Outcome History**: Identifies individuals with health conditions before vaccination.
2. **Filter Cohort**: Selects individuals without these conditions and computes key dates.
3. **Define Final Dataset**: Calculates risk periods and handles `death_date`.
4. **Identify First Event Time**: Finds the earliest occurrence of a condition.
5. **Classify Events**: Labels events as `pre_ref_event`, `risk_event`, or `post_ref_event`.
