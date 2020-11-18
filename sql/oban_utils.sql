create or replace function utc_now()
returns timestamp as $func$
begin
  return timezone('utc', now());
end $func$
language plpgsql
set search_path from current;
