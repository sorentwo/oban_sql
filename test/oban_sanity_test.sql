\unset ECHO
\set QUIET 1

\pset format unaligned
\pset tuples_only true
\pset pager off

\set ON_ERROR_ROLLBACK 1
\set ON_ERROR_STOP true

begin;

select plan(16);

-- Migration Tests

select has_table('oban_jobs');
select has_table('oban_consumers');
select is(
  obj_description(to_regclass('oban_jobs')),
  '{"version": 1, "migration": 1}',
  'current version and migration are recorded'
);

-- Extension Tests

SELECT has_extension('pgcrypto');

-- Installation Tests

select has_function('oban_loop', array['jsonb'], 'oban_loop is defined');
select has_function('oban_migrate', array['int'], 'oban_migrate is defined');
select has_function('oban_ack_job', array['bigint'], 'oban_ack_job is defined');

-- Consumer Tests

do $$
begin
perform oban_insert_consumer('web.1', 'Oban', 'alpha', '{"limit":2}');
perform oban_insert_consumer('web.2', 'Oban', 'alpha', '{"limit":3}');
perform oban_insert_consumer('web.3', 'Oban', 'gamma', '{"limit":2}');
perform oban_insert_consumer('web.4', 'Oban', 'gamma', '{"limit":3}');
end $$;

select set_eq(
  'select distinct node from oban_consumers',
  array['web.1', 'web.2', 'web.3', 'web.4'],
  'oban_consumers are inserted'
);

-- Job Fetching Tests

do $$
begin
perform oban_insert_job('alpha', 'Worker.A', '{"id": 1}');
perform oban_insert_job('alpha', 'Worker.B', '{"id": 1}', '{"tag":"yes"}');
perform oban_insert_job('alpha', 'Worker.C', '{"id": 1}', '{}', 1);
perform oban_insert_job('gamma', 'Worker.D', '{"id": 1}', '{}', 1, 1);
perform oban_insert_job('gamma', 'Worker.E', '{"id": 1}', '{}', 1, 10, utc_now() + '1 minute'::interval);
end $$;

select set_eq(
  'select distinct queue from oban_jobs',
  array['alpha', 'gamma'],
  'jobs are inserted'
);

select set_eq(
  $$ select worker from oban_fetch_jobs((select id from oban_consumers where node = 'web.1')) $$,
  array['Worker.A', 'Worker.B'],
  'jobs are fetched up to the consumer limit'
);

select set_eq(
  $$ select worker from oban_fetch_jobs((select id from oban_consumers where node = 'web.2')) $$,
  array['Worker.C'],
  'consumed jobs are not fetched again'
);

select set_eq(
  $$ select worker from oban_fetch_jobs((select id from oban_consumers where node = 'web.3')) $$,
  array['Worker.D'],
  'scheduled jobs are not fetched'
);

-- Job Acking

select results_eq(
  $$ select state, completed_at
     from oban_ack_job((select id from oban_jobs where worker = 'Worker.A')) $$,
  $$ values ('completed'::oban_job_state, utc_now()) $$,
  'acking a job marks it complete'
);

select results_eq(
  $$ select state, scheduled_at
     from oban_error_job((select id from oban_jobs where worker = 'Worker.B'), 10, 'boom') $$,
  $$ values ('retryable'::oban_job_state, utc_now() + '10 seconds') $$,
  'erroring a job with more attempts marks it retryable'
);

select results_eq(
  $$ select state, discarded_at
     from oban_error_job((select id from oban_jobs where worker = 'Worker.D'), 10, 'boom') $$,
  $$ values ('discarded'::oban_job_state, utc_now()) $$,
  'erroring a job with more attempts marks it retryable'
);

select results_eq(
  $$ select state, discarded_at
     from oban_discard_job((select id from oban_jobs where worker = 'Worker.C'), 'boom') $$,
  $$ values ('discarded'::oban_job_state, utc_now()) $$,
  'discarding a job marks it discarded'
);

select * from finish();

rollback;
