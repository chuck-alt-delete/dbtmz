{{
  config(
    materialized = 'materialized_view',
    pre_hook = [
      "DROP TABLE IF EXISTS {{ target.schema }}.t;",
      "CREATE TABLE {{ target.schema }}.t (id INT, content TEXT);",
      "INSERT INTO {{ target.schema }}.t VALUES (1, 'hi'), (2, 'hello');"
    ]
  )
}}

SELECT * FROM {{ target.database }}.{{ target.schema }}.t