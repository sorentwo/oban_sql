create or replace function oban_error_job_test()
returns setof text as $func$
declare
  consumer_id uuid;
  job_1_id bigint;
  job_2_id bigint;
begin
  select id from oban_insert_consumer('web.1', 'Oban', 'alpha', '{"limit":5}') into consumer_id;
  select id from oban_insert_job('alpha', 'Worker.A', '{}', '{}', 0, 2) into job_1_id;
  select id from oban_insert_job('alpha', 'Worker.B', '{}', '{}', 0, 1) into job_2_id;

  perform oban_fetch_jobs(consumer_id);

  return next results_eq(
    format($$ select state, scheduled_at from oban_error_job(%s, 10, 'boom') $$, job_1_id),
    $$ values ('retryable'::oban_job_state, utc_now() + '10 seconds') $$,
    'erroring a job with more attempts marks it retryable'
  );

  return next results_eq(
    format($$ select state, discarded_at from oban_error_job(%s, 10, 'boom') $$, job_2_id),
    $$ values ('discarded'::oban_job_state, utc_now()) $$,
    'erroring a job with no more attempts discards it'
  );

  return next results_eq(
    $$ select consumed_ids from oban_consumers $$,
    $$ values (array[]::bigint[]) $$,
    'erroring removes jobs from the consumer'
  );
end;
$func$ language plpgsql;
