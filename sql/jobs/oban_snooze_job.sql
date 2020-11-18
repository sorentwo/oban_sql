--
-- Reschedule an executing job to run some number of seconds in the future and release it from the
-- consumer that checked it out.
--
create or replace function oban_snooze_job(id bigint, seconds int)
returns oban_jobs as $func$
declare
  job oban_jobs;
begin
  update oban_jobs as jobs
     set state = 'scheduled',
         scheduled_at = utc_now() + format('%s seconds', seconds)::interval,
         max_attempts = jobs.max_attempts + 1
  where jobs.state = 'executing'
    and jobs.id = oban_snooze_job.id
  returning *
  into job;

  if found then
    perform oban_release_job(id);
  end if;

  return job;
end $func$
language plpgsql
set search_path from current;
