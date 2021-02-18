create or replace function oban_cron_scheduler_test()
returns setof text as $func$
begin
  return next lives_ok($$
    call oban_cron_scheduler('{
      "table": [
        {"expr": "* * * * *", "worker": "Worker.A", "queue": "alpha", "opts": {}},
        {"expr": "* * * * *", "worker": "Worker.B", "queue": "alpha", "opts": {"args": {"id": 1}}},
        {"expr": "* * * * *", "worker": "Worker.C", "queue": "alpha", "opts": {"priority": 1}},
        {"expr": "* * * * *", "worker": "Worker.D", "queue": "alpha", "opts": {"max_attempts": 1}},
        {"expr": "0 0 1 1 0", "worker": "Worker.E", "quuee": "alpha", "opts": {}}
      ]
    }')
  $$);

  return next results_eq(
    $$ select queue from oban_jobs where worker = 'Worker.A' $$,
    $$ values ('alpha') $$,
    'cron inserts without any opts'
  );

  return next results_eq(
    $$ select args from oban_jobs where worker = 'Worker.B' $$,
    $$ values ('{"id": 1}'::jsonb) $$,
    'cron inserts with custom args'
  );

  return next results_eq(
    $$ select priority, max_attempts from oban_jobs where worker = 'Worker.C' $$,
    $$ values (1, 20) $$,
    'cron inserts with custom priority'
  );

  return next results_eq(
    $$ select priority, max_attempts from oban_jobs where worker = 'Worker.D' $$,
    $$ values (0, 1) $$,
    'cron inserts with custom max_attempts'
  );

  return next results_ne(
    $$ select queue from oban_jobs where worker = 'Worker.E' $$,
    $$ values ('alpha') $$,
    'cron only inserts for expressions that evaluate to now'
  );
end $func$
language plpgsql;

create or replace function oban_cron_timezone_test()
returns setof text as $func$
declare
  utc_hour int := date_part('hour', utc_now());
  amc_hour int := date_part('hour', timezone('America/Chicago', now()));
begin
  return next lives_ok(format($$
    call oban_cron_scheduler('{
      "timezone": "America/Chicago",
      "table": [
        {"expr": "* %s * * *", "worker": "Worker.A", "queue": "alpha", "opts": {}},
        {"expr": "* %s * * *", "worker": "Worker.B", "queue": "alpha", "opts": {}}
      ]
    }')
  $$, utc_hour, amc_hour));

  return next results_eq(
    $$ select worker from oban_jobs $$,
    $$ values ('Worker.B') $$,
    'cron expressions are evaluated against the provided timezone'
  );
end $func$
language plpgsql;

create or replace function oban_cron_duplicate_test()
returns setof text as $func$
begin
  return next lives_ok($$
    call oban_cron_scheduler('{
      "table": [{"expr": "* * * * *", "worker": "Worker.A", "queue": "alpha", "opts": {}}]
    }')
  $$);

  return next lives_ok($$
    call oban_cron_scheduler('{
      "table": [{"expr": "* * * * *", "worker": "Worker.A", "queue": "alpha", "opts": {}}]
    }')
  $$);

  return next set_eq(
    $$ select count(*) from oban_jobs $$,
    array[1],
    'default uniquness prevents duplicate inserts in the same minute'
  );
end $func$
language plpgsql;

create or replace function oban_cron_reboot_test()
returns setof text as $func$
declare
  opts jsonb;
begin
  return next lives_ok($$
    call oban_cron_scheduler('{
      "table": [{"expr": "@reboot", "worker": "Worker.A", "queue": "alpha", "opts": {}}]
    }')
  $$);
end $func$
language plpgsql;
