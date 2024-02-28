-- You can explicitly specify cluster to override which cluster the index will be created on.
-- In this case, we use target.cluster, so this won't actually change anything.
{{ config(
    materialized='view',
    indexes = [
        {
            'default': True,
            'cluster': target.cluster}
    ]
    ) }}

select
    counter
from {{ source('counter_src', 'counter') }}
where counter % 2 = 0