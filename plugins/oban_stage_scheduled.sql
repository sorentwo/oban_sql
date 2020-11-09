CREATE OR REPLACE PROCEDURE oban_stage_scheduled(INOUT _opts json) AS $PROC$
DECLARE
  staged_count int;
BEGIN
  UPDATE oban_jobs
  SET state = 'available'
  WHERE state IN ('scheduled', 'retryable') AND scheduled_at <= now();

  GET DIAGNOSTICS staged_count = ROW_COUNT;

  RAISE INFO 'Staged % jobs', staged_count;
END $PROC$
LANGUAGE plpgsql
SET search_path FROM CURRENT;

