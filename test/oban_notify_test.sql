create or replace function oban_notify_test()
returns setof text as $func$
begin
  return next throws_ok(
    $$ select oban_notify('oban_random', '{}') $$,
    '22000',
    'unknown notify channel: oban_random',
    'notifying on an unknown channel raises'
  );
end $func$
language plpgsql;
