# DBT Materialize

## Initialize

    python3 -m venv venv
    source venv/bin/activate
    pip install dbt-materialize
    source .env

## Manage sources

It is typically not recommended to manage sources in `dbt` since they are considered long running infrastructure. However, it can be convenient if you have quickly evolving schemas and haven't yet set up Terraform. Here are some tips.

### Reference via `sources` in schema.yml file

See `models/sources/schema.yml` and how the source is referenced in `models/views/even_count.sql`. Now the source will be available in the lineage view of your generated `dbt docs` and referable in the rest of your project.

### Avoid rebuilding sources

Rebuilding a source can be an expensive operation because Materialize has to re-ingest all of the source data. You can avoid touching sources in `dbt` with the `--exclude` flag.

        dbt run --exclude config.materialized:source

For the Postgres source, if you have a single table you'd like to re-ingest because of a schema change, you should do so by dropping and re-creating that particular subsource ([doc](https://materialize.com/docs/sql/alter-source/#context)), creating the appropriate indexes, and then running dbt models downstream of that subsource.

### Indexes

Your sources may need indexes. The `dbt-materialize` adapter has work in progress for improved developer experience working with sources generally, but for the moment, you can use `post_hook` to run `CREATE INDEX` statements after your source is created.

## Run SQL models

Rebuilding an entire data DAG can take considerable time to rehydrate. 

Run a particular model (`--models`) and it's dependencies (`+`).

        dbt run --models ./models/views/t_mv.sql+

## Blue/Green deployment

Here are some tips for handling blue/green deployment. See `profiles.yml` for how to set up the different targets.

1. Leave your sources in public schema and don't touch them. Define them as `sources` in a `schema.yml` file. See `models/sources/schema.yml` and `models/views/even_count.sql` to see how this works.

1. Create cluster `compute_green` and schema `green` in Materialize.

1. Get everything running in cluster `compute_green` in schema `green`.

        dbt run --exclude config.materialized:source --target green 

1. Wait for `green` to rehydrate. You can look at the lag in the dependency graph in https://console.materialize.com to get a rough sense of when rehydration is complete.

1. Perform your end-to-end application tests on `green` to ensure it is safe to cut over.

1. Deploy a canary instance of your application that looks in schema `green` and connects to cluster `compute_green`. Slowly move traffic to the canary until you are confident in the new deployment. (Example for [traffic shifting in AWS Lambda](https://aws.amazon.com/blogs/compute/implementing-canary-deployments-of-aws-lambda-functions-with-alias-traffic-shifting/))

1. Drop `blue` compute objects and schema.

        drop cluster compute_blue cascade;
        drop schema blue cascade;

### Future improvements

Materialize team is working on `ALTER SCHEMA...SWAP` and `ALTER CLUSTER...SWAP` to rename schemas and clusters in such a way that the cutover will be transparent to clients. This makes the cutover easier for folks who don't use a canary deployment model or who don't want to couple application deployment to Materialize deployment.
