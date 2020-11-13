CREATE OR REPLACE FUNCTION oban_migrate() RETURNS int[] AS $FUNC$
DECLARE
  version int := 0;
  current int := 1;
  updates int[] := ARRAY[1];
  cur_idx int;
BEGIN
  version := oban_migration_version();

  CASE
  WHEN version IS NULL THEN updates := updates;
  WHEN version < current THEN updates := updates[version:current];
  ELSE RETURN ARRAY[]::int[];
  END CASE;

  FOREACH cur_idx IN ARRAY updates LOOP
    EXECUTE 'CALL ' || 'oban_migration_' || lpad(cur_idx::text, 2, '0') || '()';

    PERFORM oban_migration_version(cur_idx);
  END LOOP;

  RETURN updates;
END $FUNC$
LANGUAGE plpgsql
SET search_path FROM CURRENT;
