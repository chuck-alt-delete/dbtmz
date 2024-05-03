# DBT Materialize

## Create clusters in Materialize

Go to https://console.materialize.com and create a cluster for compute, a cluster for sources, a schema for other sources managed outside of this dbt project, and a table in that schema.

```sql
create cluster chuck size '3xsmall';
create cluster chuck_sources size '3xsmall';
set cluster = chuck_sources;
create schema other_source_schema;
set schema = other_source_schema;
create table materialize.other_source_schema.my_table (id int, content text);
insert into my_table values (1,'hi'), (2,'hello');
```

## Initialize

    python3 -m venv venv
    source venv/bin/activate
    pip install dbt-materialize
    source .env

## Manage sources

It is typically not recommended to manage sources in `dbt` since they are considered long running infrastructure. However, it can be convenient if you have quickly evolving schemas.

This project has one source managed within the project, `models/sources/counter.sql`, and one external source, a table called `t`.

### Manage sources within dbt

See `models/sources/counter.sql` for an example. One thing to note is `dbt` will prefix the given schema with the target schema. In this case, the schema defined in the model is `source_schema` and the target schema is `public`, so this will evaluate to `public_source_schema`.

### Reference external sources via `sources` in schema.yml file

If you manage sources outside of `dbt`, you can still reference them in your dbt project. See how the external source `t` is declared in `models/schema.yml` and referenced in `models/views/mv.sql`. Now the source `t` will be available in the lineage view of your generated `dbt docs` and referable in the rest of your project.

### Avoid rebuilding sources

Rebuilding a source can be an expensive operation because Materialize has to re-ingest all of the source data. You can avoid touching sources in `dbt` with the `--exclude` flag.

        dbt run --exclude config.materialized:source

For extra safety, you should make this the default behavior using [selectors.yml](./selectors.yml).

For the Postgres source, if you have a single table you'd like to re-ingest because of a schema change, you should do so by dropping and re-creating that particular subsource ([doc](https://materialize.com/docs/sql/alter-source/#context)), creating the appropriate indexes, and then running dbt models downstream of that subsource.

## Run SQL models

Rebuilding an entire data DAG can take considerable time to rehydrate. 

Run a particular model (`--models`) and it's dependencies (`+`).

        dbt run --models ./models/views/mv.sql+


## Blue/Green deployment

See https://materialize.com/docs/manage/blue-green/ for the latest documentation.

The Materialize dbt adapter now has macros to help with blue/green deployments. In this deployment, we want to
1. Create a new cluster and schema.
1. Run this dbt workload there.
1. Check if the new workload is healthy and run tests.
1. If healthy, swap out the old cluster and schema for the new and drop the old cluster and schema.
1. If not healthy, do not move forward with the swap and drop the unhealthy attempt.

### Configure deployments

In `dbt_project.yml`, create a `deployment` variable and list the clusters and schemas you want to do a blue/green deployment with. Here is an example that uses the `chuck` target. 

```yml
vars:
  deployment:
    chuck:
      clusters:
        - chuck
        - chuck_sources
      schemas:
        - public
        - public_source_schema
```

### Create deployment environment

Use the `deploy_init` macro to create a new cluster and schema. These will show up as the old cluster and schema except with `_dbt_deploy` suffixed.

```
dbt run-operation deploy_init
```

In this example, this will create these clusters:
- `chuck_dbt_deploy`
- `chuck_sources_dbt_deploy`

and these schemas:
- `public_dbt_deploy`
- `source_schema_dbt_deploy`


### Run workload in new environment

The Materialize adapter will look for the `deploy` boolean and suffix models with `dbt_deploy` to run the workload in the new deployment environment.

In this case, I manage the `counter` source inside my dbt project and I want to explicitly deploy new instance of the source.
```
dbt run --vars 'deploy: True' \
  --select models/sources/counter.sql
```

Now I deploy the rest of the models. 
```
dbt run --vars 'deploy: True'
```

### Wait for hydration

Now that the new workload is running, it needs to read all of its inputs and hydrate its state before it is ready to serve up-to-date results. This macro measures how up-to-date the new objects are and returns successfully when all objects have a lag of less than 1 second.

```
dbt run-operation deploy_await
```

### Run tests

Now you can run tests on the deployment environment to ensure it is ready for promotion.

### Promote

This macro (atomically) swaps the deploy environment for the original production environment. This swap is transparent to clients (except for `SUBSCRIBE`). They will connect to the newly deployed cluster without any configuration changes.

```
dbt run-operation deploy_promote
```

### Clean up

This macro drops the `_dbt_deploy` suffixed clusters and schemas. This will break `SUBSCRIBE` client connections still attached to the old cluster. On retry, the client will automatically connect to the newly deployed cluster without configuration changes.

```
dbt run-operation deploy_cleanup
```

### Ignore

I have a little table `t` that I like to use that gets blasted away during this process. To get back my little `t`

```
dbt seed
```