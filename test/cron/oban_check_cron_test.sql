create or replace function parse_and_check(expr text, ts timestamp)
returns boolean as $func$
begin
  return oban_check_cron(oban_parse_cron(expr), ts);
end $func$
language plpgsql;

create or replace function oban_check_cron_test()
returns setof text as $func$
declare
  new_years timestamp := '2020-01-01 00:00:00 utc';
begin
  -- wildcard matches
  return next ok(parse_and_check('* * * * *', utc_now()), 'wildcards always match');

  -- single field matches
  return next ok(parse_and_check('0 * * * *', new_years), 'literal minutes match');
  return next ok(parse_and_check('* 0 * * *', new_years), 'literal hours match');
  return next ok(parse_and_check('* * 1 * *', new_years), 'literal days match');
  return next ok(parse_and_check('* * * 1 *', new_years), 'literal months match');
  return next ok(parse_and_check('* * * * 3', new_years), 'literal days of the week match');

  -- multi field matches
  return next ok(parse_and_check('0 0 * * *', new_years), 'compound literals match');
  return next ok(parse_and_check('0 0 1 1 3', new_years), 'complete literals match');

  -- multi value matches
  return next ok(parse_and_check('0,1 * * * *', new_years), 'a list matches');
  return next ok(parse_and_check('0-5 * * * *', new_years), 'a range matches');
  return next ok(parse_and_check('* */2 * * *', new_years), 'a step matches');

  -- multi field mismatches
  return next ok(not parse_and_check('1 * * * *', new_years), 'a single value can mismatch');
  return next ok(not parse_and_check('0 1 * * *', new_years), 'partial literals mismatch');
  return next ok(not parse_and_check('0 0 1 1 0', new_years), 'the final value can mismatch');
end $func$
language plpgsql;
