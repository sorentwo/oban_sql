--
-- Check whether a cron expression matches a timestamp. By default, the time is assumed to be
-- `now()` and the timezone is `UTC`.
--
create or replace function oban_check_cron(cron jsonb, now timestamp = null)
returns boolean as $func$
declare
  field text;
  vlist jsonb;
  bool boolean := true;
begin
  now := coalesce(now, utc_now());

  for field, vlist in select * from jsonb_each(cron) loop
    bool := bool and vlist @> jsonb_build_array(date_part(field, now));
  end loop;

  return bool;
end $func$
language plpgsql
set search_path from current;
