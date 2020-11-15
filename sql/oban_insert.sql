-- %{fields: fields, keys: keys, period: period, states: states} = unique
-- abs(('x' || md5('what-the-heck-now'))::bit(64)::bigint)
-- build up the query
  -- period
  -- states
  -- worker?
  -- queue?
  -- args? (maybe by keys)
-- compute a lock

create or replace function oban_insert(
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
    state := 'available'
    scheduled_at := timezone('utc'::text, now());
  else
    state := 'scheduled'
  end if;

  if meta ? 'unique' then
    unique_query := oban_unique_query(queue, worker, args, meta->'unique');
    unique_lkey := oban_unique_lkey(queue, worker, args, meta->'unique');
  else
    unique_query := 'select true';
    unique_lkey := trunc(txid_current() * random() * 10000000)::bigint;
  end if;

  if pg_try_advisory_xact_lock(unique_lkey) and execute unique_query then
    insert into oban_jobs (queue, worker, args, meta, priority, max_attempts, state, scheduled_at)
    values (queue, worker, args, meta, priority, max_attempts, state, scheduled_at)
    on conflict do nothing
    returning *
    into job;
  end if;

  if job is not null then
    perform pg_notify('oban_insert', json_build_object('queue', job.queue)::text);
  end if;

  return job;
end $func$
language plpgsql
set search_path from current;
