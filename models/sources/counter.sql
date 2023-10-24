{{ config(
    materialized='source',
    post_hook = [
        "CREATE DEFAULT INDEX IN CLUSTER {{target.cluster}} ON {{this}}"
    ]
    ) }}

CREATE SOURCE {{this}} IN CLUSTER ingest
    FROM LOAD GENERATOR COUNTER
    (TICK INTERVAL '600ms')