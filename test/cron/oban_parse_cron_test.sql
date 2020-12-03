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

create or replace function oban_parse_cron_test()
returns setof text as $func$
begin
  -- assert valid
  return next lives_ok($$ select oban_parse_cron('* * * * *') $$);
  return next lives_ok($$ select oban_parse_cron('0 0 1 1 1') $$);
  return next lives_ok($$ select oban_parse_cron('*/2 0-4 1,2,3 * *') $$);
  return next lives_ok($$ select oban_parse_cron('* * * JAN *') $$);
  return next lives_ok($$ select oban_parse_cron('* * * * SUN') $$);

  -- assert invalid
  return next throws_ok($$ select oban_parse_cron('60 * * * *') $$);
  return next throws_ok($$ select oban_parse_cron('* 24 * * *') $$);
  return next throws_ok($$ select oban_parse_cron('* * 32 * *') $$);
  return next throws_ok($$ select oban_parse_cron('* * * 13 *') $$);
  return next throws_ok($$ select oban_parse_cron('* * * * 7') $$);
  return next throws_ok($$ select oban_parse_cron('*/0 * * * *') $$);
  return next throws_ok($$ select oban_parse_cron('ONE * * * *') $$);
  return next throws_ok($$ select oban_parse_cron('* * * jan *') $$);
  return next throws_ok($$ select oban_parse_cron('* * * * sun') $$);

  -- complete with single values
  return next is(
    oban_parse_cron('0 0 1 1 6'),
    '{"day": [1], "hour": [0], "month": [1], "minute": [0], "dow": [6]}'::jsonb,
    'expressions are expanded into name keys with array values'
  );

  -- literal value translation
  return next is(
    (oban_parse_cron('* * * JAN,MAR-JUN *'))->'month',
    '[1,3,4,5,6]'::jsonb,
    'month literals are translated'
  );

  return next is(
    (oban_parse_cron('* * * * SUN,TUE-WED'))->'dow',
    '[0,2,3]'::jsonb,
    'day of the week literals are translated'
  );

  -- assert nickname parsing

  return next is(
    oban_parse_cron('@yearly'),
    '{"day": [1], "hour": [0], "month": [1], "minute": [0], "dow": [0,1,2,3,4,5,6]}'::jsonb,
    '@ prefixed nicknames are translated and parsed'
  );

  return next is((oban_parse_cron('@annually'))->'month', '[1]'::jsonb);
  return next is((oban_parse_cron('@monthly'))->'day', '[1]'::jsonb);
  return next is((oban_parse_cron('@weekly'))->'dow', '[0]'::jsonb);
  return next is((oban_parse_cron('@daily'))->'hour', '[0]'::jsonb);
  return next is((oban_parse_cron('@midnight'))->'hour', '[0]'::jsonb);
  return next is((oban_parse_cron('@hourly'))->'minute', '[0]'::jsonb);
end $func$
language plpgsql;
