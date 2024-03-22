{{
  config(
    materialized = 'materialized_view'
  )
}}

SELECT * FROM {{ target.database }}.{{ target.schema }}.t