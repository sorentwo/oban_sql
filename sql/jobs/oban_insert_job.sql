create or replace function oban_unique_fetch(queue text, worker text, args jsonb, meta jsonb)
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
begin
  if meta ? 'unique' then
    keys := coalesce(meta #> '{unique,keys}', '[]');
    fields := coalesce(meta #> '{unique,fields}', default_fields);
    period := coalesce(meta #> '{unique,period}', default_period);
    states := coalesce(meta #> '{unique,states}', default_states);

    query := $_$ select * from oban_jobs where true $_$;

    query := query || format(
      $_$ and inserted_at > utc_now() - '%s seconds'::interval $_$,
      period
    );

    query := query || format(
      $_$ and state = any (select elem::oban_job_state from jsonb_array_elements_text('%s') elem) $_$,
      states
    );

    if jsonb_array_length(keys) > 0 then
      select jsonb_object_agg(key, value) from jsonb_each(args) where keys ? key into args;
    end if;

    if fields ? 'args' then
      query := query || format($_$ and args @> '%s' $_$, args);
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
  else
    return null;
  end if;
end $func$
language plpgsql
set search_path from current;

--
-- Dynamic uniqueness doesn't rely on an index. To prevent concurrent inserts we use an advisory
-- lock around the uniqueness scan and job insertion. The lock is composed from the queue, worker,
-- and args (only some args if `keys` is provided).
--
create or replace function oban_unique_lock(queue text, worker text, args jsonb, meta jsonb)
returns boolean as $func$
declare
begin
  if meta ? 'unique' then
    -- abs(('x' || md5('what-the-heck-now'))::bit(64)::bigint)
    return pg_try_advisory_xact_lock(1::bigint);
  else
    return true;
  end if;
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

  if oban_unique_lock(queue, worker, args, meta) then
    job := oban_unique_fetch(queue, worker, args, meta);

    if job.id is not null then
      return job;
    end if;

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
