--
-- Register a new consumer for a unique node/name/queue combination.
--
create or replace function oban_insert_consumer(
  node text,
  name text,
  queue text,
  meta jsonb
) returns oban_consumers as $func$
declare
  consumer oban_consumers;
begin
  insert
  into oban_consumers (node, name, queue, meta)
  values (node, name, queue, meta)
  returning *
  into consumer;

  return consumer;
end $func$
language plpgsql
set search_path from current;
