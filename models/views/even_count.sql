{{ config(
    materialized='view',
    indexes = [
        {'default': True}
    ]
    ) }}

select
    count(*) as even_count
from {{ref('counter')}}
where counter % 2 = 0