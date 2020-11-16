  -- BEGIN SUFFIX

  -- TODO: Combine these
  select jsonb_set(manifest, format('{%s}', 'version')::text[], released_version::text::jsonb) into manifest;
  execute format('comment on table oban_jobs is ''%s''', manifest::text);

  select jsonb_set(manifest, format('{%s}', 'migration')::text[], released_migration::text::jsonb) into manifest;
  execute format('comment on table oban_jobs is ''%s''', manifest::text);
END $$
