CREATE OR REPLACE FUNCTION oban_insert(
  queue text,
  worker text,
  args jsonb = '{}',
  meta jsonb = '{}',
  priority int = 0,
  max_attempts int = 20,
  scheduled_at timestamp = NULL,
  unique_opts jsonb = NULL
) RETURNS oban_jobs AS $FUNC$
DECLARE
  job oban_jobs;
  state oban_job_state;
  unique_query text;
  unique_lkey bigint;
BEGIN
  IF scheduled_at IS NULL THEN
    state := 'available'::oban_job_state;
    scheduled_at := timezone('UTC'::text, now());
  ELSE
    state := 'scheduled'::oban_job_state;
  END IF;

  IF unique_opts IS NULL
    unique_query := 'SELECT false';
    unique_lkey := trunc(txid_current() * random() * 10000000)::bigint;
  ELSE
    -- %{fields: fields, keys: keys, period: period, states: states} = unique
    -- abs(('x' || md5('what-the-heck-now'))::bit(64)::bigint)
    -- build up the query
      -- period
      -- states
      -- worker?
      -- queue?
      -- args? (maybe by keys)
    -- compute a lock
  END IF;

  IF pg_try_advisory_xact_lock(unique_lkey) THEN
    -- TODO: Only insert if the unique check passes, also wrap it in a lock
    INSERT INTO oban_jobs (queue, worker, args, meta, priority, max_attempts, state, scheduled_at)
    VALUES (queue, worker, args, meta, priority, max_attempts, state, scheduled_at)
    RETURNING *
    INTO job;

    -- TODO: only notify if something went in
    PERFORM pg_notify('oban_insert', json_build_object('queue', job.queue)::text);
  END IF;

  RETURN job;
END $FUNC$
LANGUAGE plpgsql
SET search_path FROM CURRENT;
