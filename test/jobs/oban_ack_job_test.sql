create or replace function oban_ack_job_test()
returns setof text as $func$
declare
  consumer_id uuid;
  job_1_id bigint;
  job_2_id bigint;
begin
  select id from oban_insert_consumer('web.1', 'Oban', 'alpha', '{"limit":2}') into consumer_id;
  select id from oban_insert_job('alpha', 'Worker.A', '{}', '{}', 0, 5) into job_1_id;
  select id from oban_insert_job('alpha', 'Worker.B', '{}', '{}', 0, 5) into job_2_id;

  perform oban_fetch_jobs(consumer_id);

  return next results_eq(
    format('select state::text, completed_at from oban_ack_job(%s)', job_1_id),
    $$ values ('completed', utc_now()) $$,
    'acking a job marks it complete'
  );

  return next results_eq(
    $$ select consumed_ids from oban_consumers $$,
    format('values (array[%s]::bigint[])', job_2_id),
    'acking removes a job from the consumer'
  );
end;
$func$ language plpgsql;
