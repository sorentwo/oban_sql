create or replace function oban_prune_jobs_test()
returns setof text as $func$
begin
  return next throws_matching(
    $$ call oban_prune_jobs('{}') $$,
    'ttl is null.*',
    'a ttl is required'
  );

  insert into oban_jobs (worker, queue, state, attempted_at, cancelled_at) values
    -- Safe because of their state
    ('A', 'alpha', 'available', now() - '61 seconds'::interval, null),
    ('B', 'alpha', 'executing', now() - '61 seconds'::interval, null),
    ('C', 'alpha', 'retryable', now() - '61 seconds'::interval, null),
    -- Safe because of the attempted_at time
    ('D', 'alpha', 'completed', now() - '30 seconds'::interval, null),
    ('E', 'alpha', 'discarded', now() - '30 seconds'::interval, null),
    -- Safe because of the cancelled_at time
    ('F', 'alpha', 'cancelled', null, now() - '30 seconds'::interval),
    -- Prunable because of the attempted_at time
    ('G', 'alpha', 'completed', now() - '61 seconds'::interval, null),
    ('H', 'alpha', 'discarded', now() - '61 seconds'::interval, null),
    -- Prunable because of the cancelled_at time
    ('I', 'alpha', 'cancelled', null, now() - '61 seconds'::interval);

  return next lives_ok(
    $$ call oban_prune_jobs('{"ttl":"1 minute"}') $$,
    'pruning succeeds with a valid ttl'
  );

  return next set_eq(
    $$ select worker from oban_jobs $$,
    '{A, B, C, D, E, F}'::text[],
    'jobs finished more recently than the ttl are retained'
  );
end $func$
language plpgsql;
