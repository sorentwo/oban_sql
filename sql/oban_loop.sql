create or replace function oban_loop(conf jsonb) returns void as $func$
declare
  name text;
  opts json;
  lkey bigint := 1235711000000000000;
begin
  loop
    if pg_try_advisory_lock(lkey) then
      -- some plugins only run every minute, right? do we need that for cron?
      for name, opts in select * from jsonb_each(conf->'plugins') loop
        execute format('call %i($1)', name) using opts;
      end loop;

      perform pg_advisory_unlock(lkey);
    end if;

    perform pg_sleep(1);
  end loop;
end $func$
language plpgsql
set search_path from current;
