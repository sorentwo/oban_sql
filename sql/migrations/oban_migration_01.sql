-- TODO: pass in schema or set the search path somehow

create or replace procedure oban_migration_01() as $proc$
begin
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
    priority integer default 0 not null,
    attempt integer default 0 not null,
    max_attempts integer default 20 not null,
    inserted_at timestamp without time zone default timezone('utc', now()) not null,
    scheduled_at timestamp without time zone default timezone('utc', now()) not null,
    attempted_at timestamp without time zone,
    completed_at timestamp without time zone,
    cancelled_at timestamp without time zone,
    discarded_at timestamp without time zone,
    queue text not null,
    worker text not null,
    args jsonb default '{}'::jsonb not null,
    meta jsonb default '{}'::jsonb not null,

    constraint queue_length check (char_length(queue) > 0),
    constraint worker_length check (char_length(worker) > 0),
    constraint priority_range check (priority between 0 and 3),
    constraint attempt_range check (attempt between 0 and max_attempts),
    constraint positive_max_attempts check (max_attempts > 0),
    constraint future_schedule check (scheduled_at >= inserted_at)
  );

  create index if not exists oban_jobs_queue_state_priority_scheduled_at_id_index
  on oban_jobs (queue, state, priority, scheduled_at, id);
end $proc$
language plpgsql;
