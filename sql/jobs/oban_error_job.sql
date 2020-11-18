--
-- Record an executing job's errors and either retry or discard it, depending on whether it has
-- exhausted its available attempts. Either way, the job is released from the consumer that
-- checked it out.
--
create or replace function oban_error_job(id bigint, seconds int, error text)
returns oban_jobs as $func$
begin
  update oban_jobs as jobs
     set state = case
                 when jobs.attempt >= jobs.max_attempts
                 then 'discarded'::oban_job_state
                 else 'retryable'::oban_job_state
                 end,
      discarded_at = case
                     when jobs.attempt >= jobs.max_attempts then utc_now()
                     else jobs.discarded_at
                     end,
      scheduled_at = case
                     when jobs.attempt >= jobs.max_attempts
                     then utc_now() + format('%s seconds', seconds)::interval
                     else jobs.scheduled_at
                     end,
      errors = jobs.errors || jsonb_build_object('attempt', jobs.attempt, 'at', utc_now(), 'error', error)
  where jobs.state = 'executing'
    and jobs.id = oban_error_job.id
  returning *;

  if found then
    perform oban_release_job(id);
  end if;

  return found;
end $func$
language plpgsql
set search_path from current;
