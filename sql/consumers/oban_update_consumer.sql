--
-- Update select parts of a consumer's `meta` field.
--
create or replace function oban_update_consumer(
  node text,
  name text,
  queue text,
  nonce text,
  meta jsonb
)
returns oban_consumers as $func$
declare
  consumer oban_consumers;
begin
  update oban_consumers as cons
     set meta = cons.meta || oban_update_consumer.meta,
         updated_at = utc_now()
  where cons.node = oban_update_consumer.node
    and cons.name = oban_update_consumer.name
    and cons.queue = oban_update_consumer.queue
    and cons.nonce = oban_update_consumer.nonce
  returning *
  into consumer;

  return consumer;
end $func$
language plpgsql
set search_path from current;
