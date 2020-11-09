CREATE OR REPLACE FUNCTION oban_loop(conf jsonb) RETURNS void AS $FUNC$
DECLARE
  name text;
  opts json;
  lkey bigint := 1235711000000000000;
BEGIN
  -- auto-migrate

  LOOP
    IF pg_try_advisory_lock(lkey) THEN
      -- some plugins only run every minute, right? Do we need that for cron?
      FOR name, opts IN SELECT * FROM jsonb_each(conf->'plugins') LOOP
        EXECUTE format('CALL %I($1)', name) USING opts;
      END LOOP;

      PERFORM pg_advisory_unlock(lkey);
    END IF;

    PERFORM pg_sleep(1);
  END LOOP;
END $FUNC$
LANGUAGE plpgsql
SET search_path FROM CURRENT;
