CREATE OR REPLACE PROCEDURE oban_stage_scheduled(INOUT _opts json) AS $PROC$
DECLARE
  staged_count int;
  queue text;
BEGIN
  FOR queue IN
    WITH updated AS (
      UPDATE oban_jobs oj
      SET state = 'available'
      WHERE oj.state IN ('scheduled', 'retryable') AND oj.scheduled_at <= now()
      RETURNING oj.queue
    ) SELECT DISTINCT(updated.queue) FROM updated
  LOOP
    PERFORM pg_notify('oban_insert', json_build_object('queue', queue)::text);
  END LOOP;

  GET DIAGNOSTICS staged_count = ROW_COUNT;

  RAISE INFO 'Staged % jobs', staged_count;
END $PROC$
LANGUAGE plpgsql
SET search_path FROM CURRENT;

