create or replace function oban_migrate(version int) returns int[] as $func$
declare
  current int := 1;
  updates int[] := array[1];
  cur_idx int;
begin
  case
  when version is null then updates := updates;
  when version < current then updates := updates[version:current];
  else return array[]::int[];
  end case;

  foreach cur_idx in array updates loop
    execute 'call ' || 'oban_migration_' || lpad(cur_idx::text, 2, '0') || '()';
  end loop;

  return updates;
end $func$
language plpgsql
set search_path from current;
