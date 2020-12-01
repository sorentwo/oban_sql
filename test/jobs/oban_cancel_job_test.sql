create or replace function oban_cancel_job_test()
returns setof text as $func$
begin
  perform oban_insert_consumer('web.1', 'Oban', 'alpha', '{"limit":2}');

  insert into oban_jobs (id, worker, queue, state) values
    (100, 'A', 'alpha', 'completed'),
    (101, 'C', 'alpha', 'cancelled'),
    (102, 'D', 'alpha', 'scheduled'),
    (103, 'E', 'alpha', 'executing');

  -- Fake that job 104 is executing
  update oban_consumers set consumed_ids = array[103];

  return next results_eq(
    $$ select state::text from oban_cancel_job(100) $$,
    $$ values (null) $$,
    'completed jobs are not cancelled'
  );

  return next results_eq(
    $$ select state::text from oban_cancel_job(101) $$,
    $$ values (null) $$,
    'previously cancelled jobs are not re-cancelled'
  );

  return next results_eq(
    $$ select state::text, cancelled_at from oban_cancel_job(102) $$,
    $$ values ('cancelled', utc_now()) $$,
    'scheduled jobs are cancelled'
  );

  return next results_eq(
    $$ select state::text, cancelled_at from oban_cancel_job(103) $$,
    $$ values ('cancelled', utc_now()) $$,
    'executing jobs are cancelled'
  );

  return next results_eq(
    $$ select consumed_ids from oban_consumers $$,
    $$ values ('{}'::bigint[]) $$,
    'cancelling removes an executing job from the consumer'
  );
end;
$func$ language plpgsql;
