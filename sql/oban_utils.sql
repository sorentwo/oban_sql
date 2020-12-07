--
-- Convience function to uniformly use UTC timestamps.
--
create or replace function utc_now()
returns timestamp as $func$
begin
  return timezone('utc', now());
end $func$
language plpgsql
set search_path from current;

--
-- Returns a new jsonb object with all the key-value pairs from `args` where the key is in `keys`.
--
create or replace function jsonb_take(args jsonb, keys jsonb)
returns jsonb as $func$
begin
  if jsonb_array_length(keys) > 0 then
    select jsonb_object_agg(key, value) from jsonb_each(args) where keys ? key into args;
  end if;

  return args;
end $func$
language plpgsql
set search_path from current;
