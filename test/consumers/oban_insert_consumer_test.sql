create or replace function oban_insert_consumer_test()
returns setof text as $$
begin
  perform oban_insert_consumer('web.1', 'Oban', 'alpha', '{"limit":2}');
  perform oban_insert_consumer('web.2', 'Oban', 'alpha', '{"limit":3}');
  perform oban_insert_consumer('web.3', 'Oban', 'gamma', '{"limit":2}');
  perform oban_insert_consumer('web.4', 'Oban', 'gamma', '{"limit":3}');

  return next set_eq(
    'select node from oban_consumers',
    array['web.1', 'web.2', 'web.3', 'web.4'],
    'oban_consumers are inserted'
  );
end;
$$ language plpgsql;
