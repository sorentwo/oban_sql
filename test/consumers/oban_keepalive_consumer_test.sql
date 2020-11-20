create or replace function oban_keepalive_consumer_test()
returns setof text as $func$
declare
  consumer_id uuid;
begin
  select id from oban_insert_consumer('web.1', 'Oban', 'alpha', '{"limit":2}') into consumer_id;

  return next set_eq(
    format('select updated_at from oban_keepalive_consumer(''%s'')', consumer_id),
    array[utc_now()],
    'oban_consumers timestamp is updated'
  );
end;
$func$ language plpgsql;
