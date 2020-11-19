create or replace procedure oban_migration_01() as $proc$
begin
  -- extensions may be installed in any schema, but only one can exist at a time. By ensuring
  -- pgcrypto is installed in the public schema we can safely call it from any function.
  create extension if not exists pgcrypto schema public;

  create type oban_job_state as enum (
    'available',
    'scheduled',
    'executing',
    'retryable',
    'completed',
    'discarded',
    'cancelled'
  );

  create table if not exists oban_jobs (
    id bigserial primary key,
    state oban_job_state default 'available'::oban_job_state not null,
    queue text not null,
    worker text not null,
    args jsonb default '{}'::jsonb not null,
    meta jsonb default '{}'::jsonb not null,
    errors jsonb default '[]'::jsonb not null,
    priority int default 0 not null,
    attempt int default 0 not null,
    max_attempts int default 20 not null,
    inserted_at timestamp without time zone default timezone('utc', now()) not null,
    scheduled_at timestamp without time zone default timezone('utc', now()) not null,
    attempted_at timestamp without time zone,
    completed_at timestamp without time zone,
    cancelled_at timestamp without time zone,
    discarded_at timestamp without time zone,

    constraint queue_length check (char_length(queue) > 0),
    constraint worker_length check (char_length(worker) > 0),
    constraint priority_range check (priority between 0 and 3),
    constraint attempt_range check (attempt between 0 and max_attempts),
    constraint positive_max_attempts check (max_attempts > 0),
    constraint future_schedule check (scheduled_at >= inserted_at)
  );

  create index if not exists oban_jobs_state_queue_priority_scheduled_at_id_index
    on oban_jobs (state, queue, priority, scheduled_at, id);

  create table if not exists oban_consumers (
    id uuid primary key default gen_random_uuid(),
    node text not null,
    name text not null,
    queue text not null,
    meta jsonb not null,
    consumed_ids bigint[] default '{}'::bigint[] not null,
    started_at timestamp without time zone default timezone('utc', now()) not null,
    updated_at timestamp without time zone default timezone('utc', now()) not null,

    constraint node_length check (char_length(node) > 0),
    constraint name_length check (char_length(name) > 0),
    constraint queue_length check (char_length(queue) > 0)
  );

  create index if not exists oban_consumers_consumed_ids_index
    on oban_consumers using gin (consumed_ids);
end $proc$
language plpgsql;
