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

  -- nickname parsing
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
