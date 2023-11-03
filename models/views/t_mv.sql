{{
  config(
    materialized = 'materialized_view',
    pre_hook = [
      "CREATE TABLE IF NOT EXISTS {{ target.schema }}.t (id INT, content TEXT);",
      "INSERT INTO {{ target.schema }}.t VALUES (1, 'hi'), (2, 'hello');"
    ]
  )
}}

SELECT * FROM {{ target.database }}.{{ target.schema }}.t