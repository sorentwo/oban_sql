create or replace function oban_listen()
returns void as $func$
declare
  channel text;
begin
  foreach channel in array '{oban_insert, oban_gossip, oban_signal}'::text[] loop
    execute format('listen "%s.%s"', current_schema(), channel);
  end loop;
end $func$
language plpgsql
set search_path from current;
