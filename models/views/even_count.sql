{{ config(
    materialized='view',
    indexes = [
        {'default': True}
    ]
    ) }}

select
    count(*) as even_count
from {{ source('counter_src', 'counter') }}
where counter % 2 = 0