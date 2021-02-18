-- NOTE:
-- Use more details for advisory lock, it only has the period
-- Release the lock manually, don't use xact

--
-- Fetch an existing job based on uniqueness criteria.
--
-- The possible unique criterion are:
--
--   * period - the number of seconds to search since a matching job was inserted. The value must
--     be a positive integer or -1, which represents infinity.
--   * fields - a list of fields to consider when matching, one or more of "args", "queue", or
--     "worker".
--   * states - a list of `oban_job_states` to consider when matching.
--   * keys - a list of keys to extract from the args map. When provided, only the subset of args
--     are considered when matching.
--
create or replace function oban_unique_fetch(queue text, worker text, args jsonb, uniq jsonb)
returns oban_jobs as $func$
declare
  query text;
  job oban_jobs;
  keys jsonb;
  fields jsonb;
  period jsonb;
  states jsonb;
  default_fields jsonb := '["args", "queue", "worker"]';
  default_period jsonb := '60';
  default_states jsonb := '["scheduled", "available", "executing", "retryable", "completed"]';
  infinite_period jsonb := '-1';
begin
  if uniq is null then
    return null;
  end if;

  keys := coalesce(uniq -> 'keys', '[]');
  fields := coalesce(uniq -> 'fields', default_fields);
  period := coalesce(uniq -> 'period', default_period);
  states := coalesce(uniq -> 'states', default_states);

  query := format($_$
    select * from oban_jobs
    where state = any (select elem::oban_job_state from jsonb_array_elements_text('%s') elem)
  $_$, states);

  if period <> infinite_period then
    query := query || format($_$ and inserted_at > utc_now() - '%s seconds'::interval $_$, period);
  end if;

  if fields ? 'args' then
    query := query || format($_$ and args @> '%s' $_$, jsonb_take(args, keys));
  end if;

  if fields ? 'queue' then
    query := query || format($_$ and queue = '%s' $_$, queue);
  end if;

  if fields ? 'worker' then
    query := query || format($_$ and worker = '%s' $_$, worker);
  end if;

  query := query || $_$ order by id limit 1 $_$;

  execute query into job;

  return job;
end $func$
language plpgsql
set search_path from current;

--
-- Try to take an advisory lock for unique job insertion.
--
-- Dynamic uniqueness doesn't rely on an index. To prevent concurrent inserts we use an advisory
-- lock around the uniqueness scan and job insertion. The lock is composed from the queue, worker,
-- and args (only some args if `keys` is provided).
--
create or replace function oban_unique_lock(queue text, worker text, args jsonb, uniq jsonb)
returns boolean as $func$
declare
  -- Advisory locks are global, across schemas. If the schema isn't included we may block
  -- concurrent inserts across schemas.
  buffer text := current_schema();
  key bigint;
begin
  if uniq is null then
    return true;
  end if;

  if uniq ? 'states' then
    buffer := buffer || (uniq->>'states');
  end if;

  if uniq->'fields' ? 'args' then
    buffer := buffer || jsonb_take(args, coalesce(uniq->'keys', '[]'))::text;
  end if;

  if uniq->'fields' ? 'queue' then
    buffer := buffer || queue;
  end if;

  if uniq->'fields' ? 'worker' then
    buffer := buffer || worker;
  end if;

  key := abs(('x' || md5(buffer))::bit(64)::bigint);

  return pg_try_advisory_xact_lock(key);
end $func$
language plpgsql
set search_path from current;

create or replace function oban_insert_job(
  queue text,
  worker text,
  args jsonb = '{}',
  meta jsonb = '{}',
  priority int = 0,
  max_attempts int = 20,
  scheduled_at timestamp = null
) returns oban_jobs as $func$
declare
  job oban_jobs;
  state oban_job_state;
  unique_query text;
  unique_lkey bigint;
begin
  if scheduled_at is null then
    state := 'available';
    scheduled_at := utc_now();
  else
    state := 'scheduled';
  end if;

  if oban_unique_lock(queue, worker, args, meta->'unique') then
    raise info 'has lock';
    job := oban_unique_fetch(queue, worker, args, meta->'unique');

    if job.id is not null then
      return job;
    end if;

    raise info 'job not found';

    insert into oban_jobs (queue, worker, args, meta, priority, max_attempts, state, scheduled_at)
    values (queue, worker, args, meta, priority, max_attempts, state, scheduled_at)
    on conflict do nothing
    returning *
    into job;

    -- Only notify if this is a new job, not when it was returned from on conflict
    if job.inserted_at >= utc_now() then
      perform oban_notify('oban_insert', json_build_object('queue', job.queue));
    end if;
  end if;

  return job;
end $func$
language plpgsql
set search_path from current;
