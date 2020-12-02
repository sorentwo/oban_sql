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

  if acc[1] < vmin then
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

create or replace function oban_parse_cron(expr text)
returns jsonb as $func$
declare
  parts text[];
begin
  select arr into parts from regexp_split_to_array(expr, '\s+') arr;

  return jsonb_build_object(
    'minutes', oban_parse_cron_expr(parts[1], 0, 59),
    'hours', oban_parse_cron_expr(parts[2], 0, 23),
    'days', oban_parse_cron_expr(parts[3], 1, 31),
    'months', oban_parse_cron_expr(parts[4], 1, 12),
    'weekdays', oban_parse_cron_expr(parts[5], 1, 7)
  );
end $func$
language plpgsql
immutable
set search_path from current;
