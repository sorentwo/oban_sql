--
-- Check whether a cron expression matches a timestamp.
--
create or replace function oban_check_cron(cron jsonb, ts timestamp)
returns boolean as $func$
declare
  field text;
  vlist jsonb;
  bool boolean := true;
begin
  for field, vlist in select * from jsonb_each(cron) loop
    bool := bool and vlist @> jsonb_build_array(date_part(field, ts));
  end loop;

  return bool;
end $func$
language plpgsql
set search_path from current;
