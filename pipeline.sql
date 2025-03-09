WITH vaccine_data AS (
    SELECT DISTINCT 
        person_id, 
        drug_exposure_id, 
        CAST(drug_concept_id AS STRING) AS drug_concept_id, 
        drug_concept_name, 
        drug_exposure_start_date, 
        drug_exposure_end_date, 
        drug_source_concept_name, 
        CAST(drug_source_concept_id AS STRING) AS drug_source_concept_id, 
        drug_source_value, 
        drug_type_concept_name, 
        CAST(drug_type_concept_id AS STRING) AS drug_type_concept_id,
        CASE 
            WHEN drug_source_concept_name LIKE '%1273%' OR drug_concept_name LIKE '%1273%' THEN 'Moderna'
            WHEN drug_source_concept_name LIKE '%162%'  OR drug_concept_name LIKE '%162%' THEN 'Pfizer'
            ELSE NULL 
        END AS vaccine_type
    FROM drug_exposure
    WHERE 
        drug_concept_id IN (SELECT concept_id FROM XBB_vaccine_concept)
        AND DATEDIFF(drug_exposure_start_date, '2023-09-11') >= 0
        AND DATEDIFF(drug_exposure_start_date, '2024-06-01') < 0
),
ordered_vaccine_data AS (
    SELECT 
        person_id,
        drug_exposure_start_date AS vax_date,
        MAX(vaccine_type) AS vax_typ,
        ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY drug_exposure_start_date) AS vax_order
    FROM vaccine_data
    GROUP BY person_id, drug_exposure_start_date
)
SELECT 
    person_id,
    MIN(CASE WHEN vax_order = 1 THEN vax_date END) AS first_vax_date,
    MAX(CASE WHEN vax_order = 1 THEN vax_typ END) AS first_vax_typ
FROM ordered_vaccine_data
GROUP BY person_id;

WITH Outcome_history AS (
    SELECT DISTINCT b.person_id
    FROM condition_occurrence a
    JOIN final_cohort b ON a.person_id = b.person_id
    WHERE condition_concept_id IN (
        SELECT concept_id FROM Outcome_concept
    )
    AND DATEDIFF(b.pre_vax_date, a.condition_start_date) > -28  
    AND DATEDIFF(b.pre_vax_date, a.condition_start_date) < 337  
),
filtered_cohort AS (
    SELECT person_id, gender, first_vax_typ AS first_XBB_type, pre_vax_date AS index_date, death_date,
           DATE_ADD(pre_vax_date, 29) AS pre_ref_start,
           DATE_SUB(first_vax_date, 14) AS pre_ref_end, 
           DATE_ADD(first_vax_date, 1) AS risk_start
    FROM final_cohort 
    WHERE person_id NOT IN (SELECT person_id FROM Outcome_history)
),
final_dataset AS (
    SELECT a.*,
        CASE 
            WHEN death_date IS NOT NULL AND DATEDIFF(death_date, risk_start) <= 28 THEN death_date
            WHEN DATEDIFF('2024-06-01', risk_start) <= 28 THEN '2024-06-01'  
            ELSE DATE_ADD(risk_start, 28)
        END AS risk_end,
        
        CASE 
            WHEN death_date IS NOT NULL AND DATEDIFF(death_date, risk_start) <= 28 THEN '2024-06-01'
            WHEN DATEDIFF('2024-06-01', risk_start) <= 28 THEN '2024-06-01'
            ELSE DATE_ADD(risk_start, 29)
        END AS post_ref_start,
        
        CASE 
            WHEN death_date IS NOT NULL AND DATEDIFF(death_date, risk_start) > 28 THEN death_date
            ELSE '2024-06-01'
        END AS post_ref_end
    FROM filtered_cohort a
),
EC AS (
    SELECT DISTINCT a.person_id, MIN(condition_start_date) AS first_event_time     
    FROM final_dataset a
    LEFT JOIN condition_occurrence b ON a.person_id = b.person_id
    WHERE condition_concept_id IN (SELECT concept_id FROM Disease_concept) 
    AND DATEDIFF(condition_start_date, pre_ref_start) >= 0 
    AND DATEDIFF(condition_start_date, post_ref_end) <= 0
    GROUP BY a.person_id
)
SELECT 
    a.*, first_event_time,
    CASE WHEN DATEDIFF(pre_ref_end, first_event_time) >= 0 THEN 1 ELSE 0 END AS pre_ref_event,
    CASE WHEN DATEDIFF(risk_end, first_event_time) >= 0 AND DATEDIFF(first_event_time, risk_start) >= 0 THEN 1 ELSE 0 END AS risk_event,
    CASE WHEN DATEDIFF(first_event_time, post_ref_start) >= 0 THEN 1 ELSE 0 END AS post_ref_event
FROM 
    final_dataset a
LEFT JOIN 
    EC b ON a.person_id = b.person_id;

