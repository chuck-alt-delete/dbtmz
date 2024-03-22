{{
config(
    materialized='source',
    indexes = [{'default': True}]
)
}}

CREATE SOURCE {{target.database}}.{{target.schema}}.counter IN CLUSTER chuck_sources
    FROM LOAD GENERATOR COUNTER
    (TICK INTERVAL '600ms')