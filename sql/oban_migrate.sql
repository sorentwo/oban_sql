create or replace function oban_migrate() returns int[] as $func$
declare
  version int := 0;
  current int := 1;
  updates int[] := array[1];
  cur_idx int;
begin
  version := oban_migration_version();

  case
  when version is null then updates := updates;
  when version < current then updates := updates[version:current];
  else return array[]::int[];
  end case;

  foreach cur_idx in array updates loop
    execute 'call ' || 'oban_migration_' || lpad(cur_idx::text, 2, '0') || '()';

    perform oban_migration_version(cur_idx);
  end loop;

  return updates;
end $func$
language plpgsql
set search_path from current;
