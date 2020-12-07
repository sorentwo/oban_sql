create or replace function oban_notify(channel text, payload json)
returns void as $func$
declare
  known_channels text[] := '{oban_insert, oban_gossip, oban_signal}';
begin
  if not array[channel] <@ known_channels then
    raise 'unknown notify channel: %', channel using errcode = 22000;
  end if;

  perform pg_notify(current_schema() || '.' || channel, payload::text);
end $func$
language plpgsql
set search_path from current;
