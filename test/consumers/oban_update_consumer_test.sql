create or replace function oban_update_consumer_test()
returns setof text as $func$
declare
  consumer_id uuid;
begin
  select id from oban_insert_consumer('web.1', 'Oban', 'alpha', '{"limit":2}') into consumer_id;

  return next results_eq(
    format($$ select meta from oban_update_consumer('%s', '{"global": true}')$$, consumer_id),
    $$ values ('{"limit": 2, "global": true}'::jsonb) $$,
    'oban_consumers meta is merged'
  );
end;
$func$ language plpgsql;
