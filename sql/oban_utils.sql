create or replace function oban_getset_comment(key text, ver int = null) returns int as $func$
declare
  manifest jsonb;
begin
  select coalesce(obj_description(to_regclass('oban_jobs')), '{}')::jsonb into manifest;

  if ver is not null then
    select jsonb_set(manifest, format('{%s}', key)::text[], ver::text::jsonb) into manifest;

    execute format('comment on table oban_jobs is ''%s''', manifest::text);
  end if;

  return (manifest->>key)::int;
end $func$
language plpgsql
set search_path from current;

create or replace function oban_functions_version(ver int = null) returns int as $func$
begin
  return oban_getset_comment('version', ver);
end $func$
language plpgsql
set search_path from current;

create or replace function oban_migration_version(ver int = null) returns int as $func$
begin
  return oban_getset_comment('migration', ver);
end $func$
language plpgsql
set search_path from current;
