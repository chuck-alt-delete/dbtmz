{{ config(
    materialized='source',
    post_hook = [
        "CREATE DEFAULT INDEX IN CLUSTER {{target.cluster}} ON {{target.database}}.public.counter"
    ]
    ) }}

CREATE SOURCE {{target.database}}.public.counter IN CLUSTER ingest
    FROM LOAD GENERATOR COUNTER
    (TICK INTERVAL '600ms')