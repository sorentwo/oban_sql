create or replace function parse_and_check(expr text, ts timestamp)
returns boolean as $func$
begin
  return oban_check_cron(oban_parse_cron(expr), ts);
end $func$
language plpgsql;

create or replace function oban_check_cron_test()
returns setof text as $func$
begin
  -- matches
  return next ok(parse_and_check('* * * * *', utc_now()), 'wildcards always match');
  return next ok(parse_and_check('0 * * * *', '2020-01-01 00:00'), 'literal minutes match');
  return next ok(parse_and_check('* 0 * * *', '2020-01-01 00:00'), 'literal hours match');
  return next ok(parse_and_check('* * 1 * *', '2020-01-01 00:00'), 'literal days match');
  return next ok(parse_and_check('* * * 1 *', '2020-01-01 00:00'), 'literal months match');
  return next ok(parse_and_check('* * * * 3', '2020-01-01 00:00'), 'literal days of the week match');

  -- multi matches
  return next ok(parse_and_check('0 0 * * *', '2020-01-01 00:00'), 'compound literals match');
  return next ok(parse_and_check('0 0 1 1 3', '2020-01-01 00:00'), 'complete literals match');

  -- mismatches
  return next ok(not parse_and_check('1 * * * *', '2020-01-01 00:00'), 'a single value can mismatch');
  return next ok(not parse_and_check('0 1 * * *', '2020-01-01 00:00'), 'partial literals mismatch');
  return next ok(not parse_and_check('0 0 1 1 0', '2020-01-01 00:00'), 'the final value can mismatch');
end $func$
language plpgsql;
