create or replace function oban_fetch_jobs_test()
returns setof text as $func$
begin
  perform oban_insert_consumer('web.1', 'Oban', 'alpha', '{"limit":2}');
  perform oban_insert_consumer('web.2', 'Oban', 'alpha', '{"limit":2}');
  perform oban_insert_consumer('web.3', 'Oban', 'gamma', '{"limit":2}');

  perform oban_insert_job('alpha', 'Worker.A', '{}', '{}', 0, 5);
  perform oban_insert_job('alpha', 'Worker.B', '{}', '{}', 0, 5);
  perform oban_insert_job('alpha', 'Worker.C', '{}', '{}', 1, 5);
  perform oban_insert_job('gamma', 'Worker.D', '{}', '{}', 1, 5);
  perform oban_insert_job('gamma', 'Worker.E', '{}', '{}', 1, 5, utc_now() + '1 minute'::interval);

  return next set_eq(
    $$ select worker from oban_fetch_jobs((select id from oban_consumers where node = 'web.1')) $$,
    array['Worker.A', 'Worker.B'],
    'jobs are fetched up to the consumer limit'
  );

  return next set_eq(
    $$ select worker from oban_fetch_jobs((select id from oban_consumers where node = 'web.2')) $$,
    array['Worker.C'],
    'consumed jobs are not fetched again'
  );

  return next set_eq(
    $$ select worker from oban_fetch_jobs((select id from oban_consumers where node = 'web.3')) $$,
    array['Worker.D'],
    'scheduled jobs are not fetched'
  );
end;
$func$ language plpgsql;
