{{
  config(
    materialized = 'materialized_view'
  )
}}

SELECT * FROM {{ source('my_table_src', 'my_table') }}