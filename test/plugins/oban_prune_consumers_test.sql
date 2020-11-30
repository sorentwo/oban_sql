create or replace function oban_prune_consumers_test()
returns setof text as $func$
begin
  return next throws_matching(
    $$ call oban_prune_consumers('{}') $$,
    'ttl is null.*',
    'a ttl is required'
  );

  insert into oban_consumers (node, name, queue, meta, updated_at) values
    ('web.1', 'oban', 'alpha', '{}', now() - '01 second'::interval),
    ('web.2', 'oban', 'gamma', '{}', now() - '59 seconds'::interval),
    ('web.3', 'oban', 'delta', '{}', now() - '61 seconds'::interval);

  return next lives_ok(
    $$ call oban_prune_consumers('{"ttl":"1 minute"}') $$,
    'pruning succeeds with a valid ttl'
  );

  return next set_eq(
    $$ select node from oban_consumers $$,
    '{web.1, web.2}'::text[],
    'consumers updated more recently than the ttl are retained'
  );
end $func$
language plpgsql;
