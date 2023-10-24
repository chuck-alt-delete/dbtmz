{{ config(materialized='source') }}

CREATE SOURCE {{this}} IN CLUSTER ingest
    FROM LOAD GENERATOR COUNTER
    (TICK INTERVAL '500ms')