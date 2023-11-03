{{ config(
    materialized='view',
    indexes = [
        {'default': True, 'cluster': target.name}
    ]
    ) }}

select
    counter
from {{ source('counter_src', 'counter') }}
where counter % 2 = 0