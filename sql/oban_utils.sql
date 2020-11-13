CREATE OR REPLACE FUNCTION oban_getset_comment(key text, ver int = NULL) RETURNS INT AS $FUNC$
DECLARE
  manifest jsonb;
BEGIN
  SELECT COALESCE(obj_description(to_regclass('oban_jobs')), '{}')::jsonb INTO manifest;

  IF ver IS NOT NULL THEN
    SELECT jsonb_set(manifest, format('{%s}', key)::text[], ver::text::jsonb) INTO manifest;

    EXECUTE format('COMMENT ON TABLE oban_jobs IS ''%s''', manifest::text);
  END IF;

  RETURN (manifest->>key)::int;
END $FUNC$
LANGUAGE plpgsql
SET search_path FROM CURRENT;

CREATE OR REPLACE FUNCTION oban_functions_version(ver int = NULL) RETURNS int AS $FUNC$
BEGIN
  RETURN oban_getset_comment('version', ver);
END $FUNC$
LANGUAGE plpgsql
SET search_path FROM CURRENT;

CREATE OR REPLACE FUNCTION oban_migration_version(ver int = NULL) RETURNS int AS $FUNC$
BEGIN
  RETURN oban_getset_comment('migration', ver);
END $FUNC$
LANGUAGE plpgsql
SET search_path FROM CURRENT;
