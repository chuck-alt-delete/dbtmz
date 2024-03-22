-- You can explicitly specify cluster to override which cluster the index will be created on.
-- In this case, we use target.cluster, so this won't actually change anything.
{{
    config(
        materialized='view',
        indexes=[
            {
                'columns': ['id'],
                'cluster': target.cluster
            }
        ]
    )
}}

SELECT
    id
    , UPPER(content)
FROM {{ ref('mv') }}