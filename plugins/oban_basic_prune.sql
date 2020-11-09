CREATE OR REPLACE PROCEDURE oban_basic_prune(INOUT opts json) AS $PROC$
DECLARE
  pruned_count int;
BEGIN
  DELETE FROM oban_jobs oj0
  WHERE oj0.id IN (
    SELECT id
    FROM oban_jobs oj1
    WHERE oj1.state IN ('completed', 'cancelled', 'discarded')
      AND (
        oj1.attempted_at < now() - (opts->>'interval')::interval
        OR
        oj1.cancelled_at < now() - (opts->>'interval')::interval
      )
  );

  GET DIAGNOSTICS pruned_count = ROW_COUNT;

  RAISE INFO 'Pruned % jobs', pruned_count;
END $PROC$
LANGUAGE plpgsql
SET search_path FROM CURRENT;
