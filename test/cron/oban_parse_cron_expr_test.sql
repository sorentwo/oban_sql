create or replace function oban_parse_cron_expr_test()
returns setof text as $func$
begin
  -- literals
  return next is(oban_parse_cron_expr('0', 0, 59), array[0]);
  return next is(oban_parse_cron_expr('0,1,2', 0, 59), array[0,1,2]);

  -- wildcard
  return next is(array_length(oban_parse_cron_expr('*', 1, 7), 1), 7);

  -- ranges
  return next is(oban_parse_cron_expr('0-2', 0, 59), array[0,1,2]);
  return next is(oban_parse_cron_expr('0-2,4-6', 0, 59), array[0,1,2,4,5,6]);

  -- steps
  return next is(oban_parse_cron_expr('*/5', 0, 59), array[0,5,10,15,20,25,30,35,40,45,50,55]);
  return next is(oban_parse_cron_expr('*/15', 0, 59), array[0,15,30,45]);

  -- overlaps
  return next is(oban_parse_cron_expr('0, */15, 14-15', 0, 59), array[0,14,15,30,45]);

  -- unknown syntax
  return next throws_ok(
    $$ select oban_parse_cron_expr('ONE', 0, 59) $$,
    22000,
    'unknown expression: ONE',
    'parsing unknown expressions raises'
  );

  -- out of bounds
  return next throws_ok(
    $$ select oban_parse_cron_expr('60', 0, 59) $$,
    22000,
    'cron value is too high: 60 (0-59)',
    'out of bounds values raises'
  );
end $func$
language plpgsql;
