{{
config(
    materialized = 'source',
    schema = 'source_schema',
    cluster = 'chuck_sources'
)
}}

FROM LOAD GENERATOR COUNTER
    (TICK INTERVAL '600ms')