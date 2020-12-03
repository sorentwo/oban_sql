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

create or replace function oban_translate_literals(expr text, names text[], off int)
returns text as $func$
declare
  str text;
  idx int;
begin
  for str, idx in select * from unnest(names) with ordinality loop
    expr := replace(expr, str, (idx - off)::text);
  end loop;

  return expr;
end $func$
language plpgsql
immutable
set search_path from current;

create or replace function oban_parse_cron(expr text)
returns jsonb as $func$
declare
  parts text[];
  month_names text[] := '{JAN, FEB, MAR, APR, MAY, JUN, JUL, AUG, SEP, OCT, NOV, DEC}'::text[];
  dow_names text[] := '{SUN, MON, TUE, WED, THU, FRI, SAT}'::text[];
begin
  select arr into parts from regexp_split_to_array(expr, '\s+') arr;

  return jsonb_build_object(
    'minute', oban_parse_cron_expr(parts[1], 0, 59),
    'hour', oban_parse_cron_expr(parts[2], 0, 23),
    'day', oban_parse_cron_expr(parts[3], 1, 31),
    'month', oban_parse_cron_expr(oban_translate_literals(parts[4], month_names, 0), 1, 12),
    'dow', oban_parse_cron_expr(oban_translate_literals(parts[5], dow_names, 1), 0, 6)
  );
end $func$
language plpgsql
immutable
set search_path from current;
