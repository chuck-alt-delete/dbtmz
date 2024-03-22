# DBT Materialize

## Create clusters in Materialize

Go to https://console.materialize.com and create some clusters.

```sql
create cluster chuck size '3xsmall';
create cluster chuck_sources size '3xsmall';
```

## Initialize

    python3 -m venv venv
    source venv/bin/activate
    pip install dbt-materialize
    source .env

## Manage sources

It is typically not recommended to manage sources in `dbt` since they are considered long running infrastructure. However, it can be convenient if you have quickly evolving schemas and haven't yet set up Terraform. Here are some tips.

### Reference via `sources` in schema.yml file

See `models/schema.yml` and how the source is referenced in `models/views/even_count.sql`. Now the source will be available in the lineage view of your generated `dbt docs` and referable in the rest of your project.

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

This particular project requires a seed table called `t`. Create and populate this table with

```
dbt seed
```

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
      schemas:
        - public
```

### Create deployment environment

Use the `deploy_init` macro to create a new cluster and schema. These will show up as the old cluster and schema except with `_dbt_deploy` suffixed.

```
dbt run-operation deploy_init
```

In this example, this will create a cluster `chuck_dbt_deploy` and a schema `public_dbt_deploy`.

### Create seed table in new environment

Ignore this step unless you are running this specific project.

As a quirk of my workload in this project, I have a seed table. As of writing, the Materialize adapter doesn't yet support the `table` materialization, and I don't want to configure a separate target for the deploy environment, so this needs to be run separately in a SQL shell.

```sql
set cluster = chuck_dbt_deploy;
set schema = public_dbt_deploy;
create table t (id int, content text);
insert into t values (1,'hi'), (2,'hello');
```

### Run workload in new environment

The Materialize adapter will look for the `deploy` boolean and suffix models with `dbt_deploy` to run the workload in the new deployment environment.

```
dbt run --vars 'deploy: True' --exclude config.materialized:source
```

In this case we also exclude the source since we intend to continue using the original.

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
