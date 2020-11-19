--
-- Refresh a consumer's `updated_at` timestamp to indicate that the associated client is still
-- alive.
--
create or replace function oban_keepalive_consumer(id uuid)
returns oban_consumers as $func$
declare
  consumer oban_consumers;
begin
  update oban_consumers as cons
     set updated_at = timezone('utc', now())
  where cons.id = oban_keepalive_consumer.id
  returning *
  into consumer;

  return consumer;
end $func$
language plpgsql
set search_path from current;
