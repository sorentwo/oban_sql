create or replace function oban_insert_jobs_test()
returns setof text as $func$
begin
  perform oban_insert_job('alpha', 'Worker.A', '{"id": 1}');
  perform oban_insert_job('alpha', 'Worker.B', '{"id": 1}', '{"tag":"yes"}');
  perform oban_insert_job('alpha', 'Worker.C', '{"id": 1}', '{}', 1);
  perform oban_insert_job('gamma', 'Worker.D', '{"id": 1}', '{}', 1, 1);
  perform oban_insert_job('gamma', 'Worker.E', '{"id": 1}', '{}', 1, 10, utc_now() + '1 minute'::interval);

  return next set_eq(
    'select distinct queue from oban_jobs',
    array['alpha', 'gamma'],
    'jobs are inserted'
  );
end;
$func$ language plpgsql;
