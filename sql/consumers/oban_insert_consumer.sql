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
  nonce text;
  consumer oban_consumers;
begin
  nonce := encode(gen_random_bytes(12), 'base64');

  insert
  into oban_consumers (node, name, queue, nonce, meta)
  values (node, name, queue, nonce, meta)
  returning *
  into consumer;

  return consumer;
end $func$
language plpgsql
set search_path from current;
