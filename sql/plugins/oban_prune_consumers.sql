create or replace procedure oban_prune_consumers(inout opts jsonb) as $proc$
declare
  ttl interval;
  pruned_count int;
begin
  ttl := (opts->>'ttl')::interval;

  if ttl is null then
    raise 'ttl is null or no ttl provided' using errcode = 22004;
  end if;

  delete from oban_consumers where updated_at < now() - ttl;

  get diagnostics pruned_count = row_count;

  raise info 'oban_prune_consumers: pruned %', pruned_count;
end $proc$
language plpgsql
set search_path from current;
