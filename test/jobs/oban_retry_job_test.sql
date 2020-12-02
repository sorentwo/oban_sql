create or replace function oban_retry_job_test()
returns setof text as $func$
begin
  insert into oban_jobs (id, queue, worker, state) values
    (100, 'alpha', 'Worker', 'discarded');

  return next results_eq(
    $$ select state::text, max_attempts, scheduled_at from oban_retry_job(100) $$,
    $$ values ('available', 20, utc_now()) $$,
    'retrying a discarded job schedules it immediately'
  );
end;
$func$ language plpgsql;
