--
-- Refresh a consumer's `updated_at` timestamp to indicate that the associated client is still
-- alive.
--
create or replace function oban_keepalive_consumer(
  node text,
  name text,
  queue text,
  nonce text
)
returns oban_consumers as $func$
declare
  consumer oban_consumers;
begin
  update oban_consumers as cons
     set updated_at = timezone('utc', now())
  where cons.node = oban_keepalive_consumer.node
    and cons.name = oban_keepalive_consumer.name
    and cons.queue = oban_keepalive_consumer.queue
    and cons.nonce = oban_keepalive_consumer.nonce
  returning *
  into consumer;

  return consumer;
end $func$
language plpgsql
set search_path from current;
