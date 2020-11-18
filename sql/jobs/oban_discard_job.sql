--
-- Mark an executing job as discarded and release it from the consumer that checked it out.
--
create or replace function oban_discard_job(id bigint, formatted text)
returns oban_jobs as $func$
begin
  update oban_jobs as jobs
     set state = 'discarded',
         discarded_at = utc_now(),
         errors = jobs.errors || jsonb_build_object('attempt', jobs.attempt, 'at', utc_now(), 'error', error)
   where jobs.state = 'executing'
     and jobs.id = oban_discard_job.id
   returning *;

  if found then
    perform oban_release_job(id);
  end if;

  return found;
end $func$
language plpgsql
set search_path from current;
