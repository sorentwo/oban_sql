create or replace function oban_installation_test()
returns setof text as $$
begin
  return next has_function('oban_loop', array['jsonb'], 'oban_loop is defined');
  return next has_function('oban_migrate', array['int'], 'oban_migrate is defined');
  return next has_function('oban_ack_job', array['bigint'], 'oban_ack_job is defined');
end;
$$ language plpgsql;
