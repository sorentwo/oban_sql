--
-- Mark a job as `available` while incrementing max_attempts if they've already maxed out. Only
-- jobs that are `retryable`, `discarded` or `cancelled` may be retried.
--
create or replace function oban_retry_job(id bigint)
returns oban_jobs as $func$
declare
  job oban_jobs;
begin
  update oban_jobs as jobs
     set state = 'available',
         max_attempts = greatest(jobs.max_attempts, jobs.attempt + 1),
         scheduled_at = utc_now(),
         completed_at = null,
         cancelled_at = null,
         discarded_at = null
  where jobs.id = oban_retry_job.id
    and jobs.state in ('retryable', 'discarded', 'cancelled')
  returning *
  into job;

  return job;
end $func$
language plpgsql
set search_path from current;
