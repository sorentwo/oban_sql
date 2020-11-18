--
-- Acknowledge that an executing job is complete and release it from the consumer that checked it
-- out.
--
create or replace function oban_ack_job(id bigint)
returns oban_jobs as $func$
begin
  update oban_jobs as jobs
     set state = 'completed',
         completed_at = utc_now()
  where jobs.state = 'executing'
    and jobs.id = oban_ack_job.id
  returning *;

  if found then
    perform oban_release_job(id);
  end if;

  return found;
end $func$
language plpgsql
set search_path from current;
