{{
    config(
        materialized='view',
        indexes=[
            {'columns': ['id'], 'cluster': target.name}
        ]
    )
}}

SELECT
    id
    , UPPER(content)
FROM {{ ref('t_mv') }}