--
-- Cancel an `available`, `scheduled` or `retryable` job and mark it as `discarded` to prevent it
-- from running. If the job is currently `executing` it will be killed.
--
create or replace function oban_cancel_job(id bigint)
returns oban_jobs as $func$
declare
  init_state text;
  job oban_jobs;
begin
  select state::text
  from oban_jobs jobs
  where jobs.id = oban_cancel_job.id
  into init_state;

  update oban_jobs as jobs
     set state = 'cancelled',
         cancelled_at = utc_now()
  where jobs.id = oban_cancel_job.id
    and jobs.state not in ('completed', 'discarded', 'cancelled')
  returning *
  into job;

  if found and init_state = 'executing' then
    perform oban_release_job(id);
    perform oban_notify('oban_signal', json_build_object('action', 'pkill', 'job_id', id));
  end if;

  return job;
end $func$
language plpgsql
set search_path from current;
