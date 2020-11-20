create or replace function oban_discard_job_test()
returns setof text as $func$
declare
  consumer_id uuid;
  job_id bigint;
begin
  select id from oban_insert_consumer('web.1', 'Oban', 'alpha', '{"limit":5}') into consumer_id;
  select id from oban_insert_job('alpha', 'Worker.A') into job_id;

  perform oban_fetch_jobs(consumer_id);

  return next results_eq(
    format($$ select state, discarded_at from oban_discard_job(%s, 'boom') $$, job_id),
    $$ values ('discarded'::oban_job_state, utc_now()) $$,
    'discarding a job marks it discarded'
  );

  return next results_eq(
    $$ select consumed_ids from oban_consumers $$,
    $$ values (array[]::bigint[]) $$,
    'discarding removes jobs from the consumer'
  );
end;
$func$ language plpgsql;
