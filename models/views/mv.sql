{{
  config(
    materialized = 'materialized_view'
  )
}}

SELECT * FROM {{ source('table_src', 'table') }}