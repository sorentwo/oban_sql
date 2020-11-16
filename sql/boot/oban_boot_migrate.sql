  -- BEGIN BOOT MIGRATE

  if current_migration is not null and current_migration >= released_migration then
    raise info 'oban already at migration %', current_migration;
  else
    perform oban_migrate(current_migration);
  end if;

  -- END BOOT MIGRATE
