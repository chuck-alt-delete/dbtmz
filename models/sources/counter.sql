{{
config(
    materialized='source'
)
}}

-- hard coding schema and cluster to treat as an external source
CREATE SOURCE {{target.database}}.source_schema.counter IN CLUSTER chuck_sources
    FROM LOAD GENERATOR COUNTER
    (TICK INTERVAL '600ms')