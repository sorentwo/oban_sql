create or replace function oban_migration_test()
returns setof text as $$
begin
  return next has_table('oban_jobs');
  return next has_table('oban_consumers');

  return next is(
    obj_description(to_regclass('oban_jobs')),
    '{"version": 1, "migration": 1}',
    'current version and migration are recorded'
  );

  return next has_extension('pgcrypto');
end;
$$ language plpgsql;
