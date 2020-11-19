--
-- Update select parts of a consumer's `meta` field.
--
create or replace function oban_update_consumer(id uuid, meta jsonb)
returns oban_consumers as $func$
declare
  consumer oban_consumers;
begin
  update oban_consumers as cons
     set meta = cons.meta || oban_update_consumer.meta,
         updated_at = utc_now()
  where cons.id = oban_update_consumer.id
  returning *
  into consumer;

  return consumer;
end $func$
language plpgsql
set search_path from current;
