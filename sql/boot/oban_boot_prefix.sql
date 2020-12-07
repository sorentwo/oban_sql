do $$
declare
  manifest jsonb;
  current_version int;
  current_migration int;
  released_version int := 1;
  released_migration int := 1;
begin
  select coalesce(obj_description(to_regclass('oban_jobs')), '{}')::jsonb into manifest;

  current_version := (manifest->>'version')::int;
  current_migration := (manifest->>'migration')::int;

  if current_version is not null and current_version >= released_version then
    raise info 'oban already at version %', current_version;

    return;
  end if;

  -- END BOOT PREFIX
