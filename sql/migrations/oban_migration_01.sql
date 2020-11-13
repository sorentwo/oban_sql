-- TODO: pass in schema or set the search path somehow

CREATE OR REPLACE PROCEDURE oban_migration_01() AS $PROC$
BEGIN
  CREATE TYPE oban_job_state AS ENUM (
    'available',
    'scheduled',
    'executing',
    'retryable',
    'completed',
    'discarded',
    'cancelled'
  );

  CREATE TABLE IF NOT EXISTS oban_jobs (
    id bigserial PRIMARY KEY,
    state oban_job_state DEFAULT 'available'::oban_job_state NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    attempt integer DEFAULT 0 NOT NULL,
    max_attempts integer DEFAULT 20 NOT NULL,
    inserted_at timestamp without time zone DEFAULT timezone('UTC', now()) NOT NULL,
    scheduled_at timestamp without time zone DEFAULT timezone('UTC', now()) NOT NULL,
    attempted_at timestamp without time zone,
    completed_at timestamp without time zone,
    cancelled_at timestamp without time zone,
    discarded_at timestamp without time zone,
    queue text NOT NULL,
    worker text NOT NULL,
    args jsonb DEFAULT '{}'::jsonb NOT NULL,
    meta jsonb DEFAULT '{}'::jsonb NOT NULL,

    CONSTRAINT queue_length CHECK (char_length(queue) > 0),
    CONSTRAINT worker_length CHECK (char_length(worker) > 0),
    CONSTRAINT priority_range CHECK (priority BETWEEN 0 AND 3),
    CONSTRAINT attempt_range CHECK (attempt BETWEEN 0 AND max_attempts),
    CONSTRAINT positive_max_attempts CHECK (max_attempts > 0),
    CONSTRAINT future_schedule CHECK (scheduled_at >= inserted_at)
  );

  CREATE INDEX IF NOT EXISTS oban_jobs_queue_state_priority_scheduled_at_id_index
  ON oban_jobs (queue, state, priority, scheduled_at, id);
END $PROC$
LANGUAGE plpgsql;
