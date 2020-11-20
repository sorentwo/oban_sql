create or replace function oban_retry_job_test()
returns setof text as $func$
declare
  job_1_id bigint;
begin
  insert into oban_jobs (queue, worker, state)
  values ('alpha', 'Worker', 'discarded')
  returning id
  into job_1_id;

  return next results_eq(
    format($$ select state, max_attempts, scheduled_at from oban_retry_job(%s) $$, job_1_id),
    $$ values ('available'::oban_job_state, 20, utc_now()) $$,
    'retrying a discarded job schedules it immediately'
  );
end;
$func$ language plpgsql;
