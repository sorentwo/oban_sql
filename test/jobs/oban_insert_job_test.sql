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
end
$func$ language plpgsql;

create or replace function oban_unique_fields_test()
returns setof text as $func$
begin
  insert into oban_jobs (id, queue, worker, args) values
    (100, 'alpha', 'Worker.A', '{"id": 1}'),
    (101, 'gamma', 'Worker.A', '{"id": 2}'),
    (102, 'delta', 'Worker.B', '{"id": 3}');

  return next set_eq(
    $$ select id from oban_insert_job('alpha', 'Worker.B', '{}', '{"unique": {"fields": ["queue"]}}') $$,
    array[100],
    'uniqueness is enforced by queue'
  );

  return next set_eq(
    $$ select id from oban_insert_job('alpha', 'Worker.B', '{}', '{"unique": {"fields": ["worker"]}}') $$,
    array[102],
    'uniqueness is enforced by worker'
  );

  return next set_eq(
    $$ select id from oban_insert_job('gamma', 'Worker.A', '{}', '{"unique": {"fields": ["queue", "worker"]}}') $$,
    array[101],
    'uniqueness is enforced by queue and worker'
  );

  return next set_ne(
    $$ select id from oban_insert_job('delta', 'Worker.A', '{}', '{"unique": {"fields": ["queue", "worker"]}}') $$,
    array[101],
    'insert is allowed with mismatched queue and worker'
  );

  return next set_eq(
    $$ select id from oban_insert_job('alpha', 'Worker.A', '{"id": 1}', '{"unique": {"fields": ["args"]}}') $$,
    array[100],
    'uniqueness is enforced by args'
  );

  return next set_eq(
    $$ select id from oban_insert_job('alpha', 'Worker.A', '{"id": 1}', '{"unique": {"fields": ["args", "worker"]}}') $$,
    array[100],
    'uniqueness is enforced by worker and args'
  );

  return next set_ne(
    $$ select id from oban_insert_job('alpha', 'Worker.A', '{"id": 2}', '{"unique": {"fields": ["args", "worker"]}}') $$,
    array[100],
    'insert is allowed with mismatched worker and args'
  );
end
$func$ language plpgsql;

create or replace function oban_unique_fields_test()
returns setof text as $func$
begin
  insert into oban_jobs (id, queue, worker, args) values
    (100, 'alpha', 'Worker.A', '{"id": 1, "url": "a.co"}'),
    (101, 'alpha', 'Worker.A', '{"id": 2, "url": "b.co"}');

  return next set_eq(
    $$ select id from oban_insert_job(
      'alpha', 'Worker.A', '{"id": 1, "url": "c.co"}', '{"unique": {"keys": ["id"]}}')
    $$,
    array[100],
    'uniqueness is enforced by only id key'
  );

  return next set_eq(
    $$ select id from oban_insert_job(
      'alpha', 'Worker.A', '{"id": 3, "url": "a.co"}', '{"unique": {"keys": ["url"]}}')
    $$,
    array[100],
    'uniqueness is enforced by only url key'
  );

  return next set_ne(
    $$ select id from oban_insert_job(
      'alpha', 'Worker.A', '{"id": 2, "url": "c.co"}', '{"unique": {"keys": ["url"]}}')
    $$,
    array[101],
    'insert is allowed with a single mismatched key'
  );
end
$func$ language plpgsql;

create or replace function oban_unique_states_test()
returns setof text as $func$
begin
  insert into oban_jobs (id, queue, worker, state) values
    (100, 'alpha', 'Worker.A', 'available'),
    (101, 'alpha', 'Worker.B', 'completed'),
    (102, 'alpha', 'Worker.C', 'executing');

  return next set_eq(
    $$ select id from oban_insert_job(
      'alpha', 'Worker.A', '{}', '{"unique": {"fields": ["worker"], "states": ["available"]}}')
    $$,
    array[100],
    'uniqueness is enforced by available state'
  );

  return next set_ne(
    $$ select id from oban_insert_job(
      'alpha', 'Worker.A', '{}', '{"unique": {"fields": ["worker"], "states": ["completed"]}}')
    $$,
    array[100],
    'insert is allowed when state does not match'
  );
end
$func$ language plpgsql;

create or replace function oban_unique_period_test()
returns setof text as $func$
begin
  insert into oban_jobs (id, queue, worker, inserted_at) values
    (100, 'alpha', 'Worker.A', utc_now() - '1 minute'::interval),
    (101, 'alpha', 'Worker.B', utc_now() - '1 year'::interval);

  return next set_eq(
    $$ select id from oban_insert_job('alpha', 'Worker.A', '{}', '{"unique": {"period": 61}}') $$,
    array[100],
    'uniqueness is enforced within a period'
  );

  return next set_ne(
    $$ select id from oban_insert_job('alpha', 'Worker.A', '{}', '{"unique": {"period": 59}}') $$,
    array[100],
    'insert is allowed after the period'
  );

  return next set_eq(
    $$ select id from oban_insert_job('alpha', 'Worker.B', '{}', '{"unique": {"period": -1}}') $$,
    array[101],
    'an infinite period is unique across all jobs'
  );
end
$func$ language plpgsql;
