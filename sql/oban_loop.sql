--
-- Start the core oban loop, which runs plugin procedures in an infinite timed loop.
--
-- Plugins are specified as `name` => `opts` pairs, where the name is a loaded procedure and the
-- opts are a JSON object. The structure of opts is flexible and plugin dependent, except for a
-- standard `interval` option. Intervals are specified in seconds, which determines how frequently
-- a plugin is invoked, at most once per second.
--
create or replace function oban_loop(conf jsonb) returns void as $func$
declare
  name text;
  opts json;
  iter int := 0;
  lkey bigint := 1235711000000000000;
begin
  if not pg_try_advisory_lock(lkey) then
    raise info 'oban loop for % already running', lkey;
  end if;

  loop
    for name, opts in select * from jsonb_each(conf->'plugins') loop
      if mod(iter, coalesce((opts->>'interval')::int, 1)) = 0 then
        execute format('call %I($1)', name) using opts;
      end if;
    end loop;

    iter := iter + 1;

    perform pg_sleep(1);
  end loop;
end $func$
language plpgsql
set search_path from current;
