create or replace function oban_release_job(id bigint) returns void as $func$
begin
  update oban_consumers as cons
  set consumed_ids = array_remove(cons.consumed_ids, id)
  where cons.consumed_ids @> array[id];
end $func$
language plpgsql
set search_path from current;
