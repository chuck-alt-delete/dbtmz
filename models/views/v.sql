{{
    config(
        materialized='view',
        indexes=[
            {'columns': ['id']}
        ]
    )
}}

SELECT
    id
    , UPPER(content)
FROM {{ ref('t_mv') }}