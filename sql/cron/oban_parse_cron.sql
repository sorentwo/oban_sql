create or replace function oban_parse_cron_expr(expr text, vmin int, vmax int)
returns int[] as $func$
declare
  part text;
  step int;
  rmin int;
  rmax int;
  acc int[] := '{}'::int[];
begin
  foreach part in array regexp_split_to_array(expr, '\s*,\s*') loop
    case
    when part ~ '^\*$' then
      acc := acc || array(select generate_series(vmin, vmax));
    when part ~ '^\d+$' then
      acc := acc || part::int;
    when part ~ '^\*\/\d+$' then
      step := replace(part, '*/', '')::int;
      acc := acc || array(select generate_series(vmin, vmax, step));
    when part ~ '^\d+\-\d+$' then
      rmin := split_part(part, '-', 1);
      rmax := split_part(part, '-', 2);
      acc := acc || array(select generate_series(rmin, rmax));
    else
      raise 'unknown expression: %', part using errcode = 22000;
    end case;
  end loop;

  select min(elem), max(elem)
  from unnest(acc) as arr(elem)
  into rmin, rmax;

  if rmin < vmin then
    raise 'cron value is too low: % (%-%)', rmin, vmin, vmax using errcode = 22000;
  elsif rmax > vmax then
    raise 'cron value is too high: % (%-%)', rmax, vmin, vmax using errcode = 22000;
  end if;

  return array(
    select distinct elem
    from unnest(acc) as arr(elem)
    order by elem
  );
end $func$
language plpgsql
immutable
set search_path from current;

--
-- Translate common month shorthand into a numerical value.
--
create or replace function oban_translate_month(expr text)
returns text as $func$
begin
  expr := replace(expr, 'JAN', '1');
  expr := replace(expr, 'FEB', '2');
  expr := replace(expr, 'MAR', '3');
  expr := replace(expr, 'APR', '4');
  expr := replace(expr, 'MAY', '5');
  expr := replace(expr, 'JUN', '6');
  expr := replace(expr, 'JUL', '7');
  expr := replace(expr, 'AUG', '8');
  expr := replace(expr, 'SEP', '9');
  expr := replace(expr, 'OCT', '10');
  expr := replace(expr, 'NOV', '11');
  expr := replace(expr, 'DEC', '12');

  return expr;
end $func$
language plpgsql
immutable
set search_path from current;

--
-- Translate common day of the week shorthand into a numerical value.
--
create or replace function oban_translate_dow(expr text)
returns text as $func$
begin
  expr := replace(expr, 'SUN', '0');
  expr := replace(expr, 'MON', '1');
  expr := replace(expr, 'TUE', '2');
  expr := replace(expr, 'WED', '3');
  expr := replace(expr, 'THU', '4');
  expr := replace(expr, 'FRI', '5');
  expr := replace(expr, 'SAT', '6');

  return expr;
end $func$
language plpgsql
immutable
set search_path from current;

--
-- Translate common cron nicknames into common expressions. The following are supported:
--
-- @yearly: Run once a year, "0 0 1 1 *".
-- @annually: same as @yearly
-- @monthly: Run once a month, "0 0 1 * *".
-- @weekly: Run once a week, "0 0 * * 0".
-- @daily: Run once a day, "0 0 * * *".
-- @midnight: same as @daily
-- @hourly: Run once an hour, "0 * * * *".
--
create or replace function oban_translate_nickname(expr text)
returns text as $func$
begin
  expr := replace(expr, '@yearly', '0 0 1 1 *');
  expr := replace(expr, '@annually', '0 0 1 1 *');
  expr := replace(expr, '@monthly', '0 0 1 * *');
  expr := replace(expr, '@weekly', '0 0 * * 0');
  expr := replace(expr, '@daily', '0 0 * * *');
  expr := replace(expr, '@midnight', '0 0 * * *');
  expr := replace(expr, '@hourly', '0 * * * *');

  return expr;
end $func$
language plpgsql
immutable
set search_path from current;

--
-- Parse cron expressions into a map of time keys (minute, hour, etc) and value lists.
--
create or replace function oban_parse_cron(expr text)
returns jsonb as $func$
declare
  parts text[];
begin
  select * into parts from regexp_split_to_array(oban_translate_nickname(expr), '\s+');

  return jsonb_build_object(
    'minute', oban_parse_cron_expr(parts[1], 0, 59),
    'hour', oban_parse_cron_expr(parts[2], 0, 23),
    'day', oban_parse_cron_expr(parts[3], 1, 31),
    'month', oban_parse_cron_expr(oban_translate_month(parts[4]), 1, 12),
    'dow', oban_parse_cron_expr(oban_translate_dow(parts[5]), 0, 6)
  );
end $func$
language plpgsql
immutable
set search_path from current;
