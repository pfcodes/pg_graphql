begin;
    set client_min_messages to error;
    --set log_min_messages to panic;

    create schema xyz;
    create type xyz.light as enum ('red');

    select graphql.rebuild_schema();

    -- expect nothing b/c not in search_path
    select name from graphql.type t where t.enum is not null;

    set search_path = 'xyz';

    -- expect 1 record
    select name from graphql.type t where t.enum is not null;

    revoke all on type xyz.light from public;

    -- Create low priv user without access to xyz.light
    create role low_priv;

    -- expected false
    select pg_catalog.has_type_privilege(
        'low_priv',
        'xyz.light',
        'USAGE'
    );

    grant usage on schema xyz to low_priv;
    grant usage on schema graphql to low_priv;
    grant select on graphql.field to low_priv;
    grant select on graphql.type to low_priv;
    grant select on graphql.enum_value to low_priv;

    set role low_priv;

    -- expect no results b/c low_priv does not have usage permission
    select name from graphql.type t where t.enum is not null;

rollback;
