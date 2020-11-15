create or replace procedure oban_basic_prune(inout opts json) as $proc$
declare
  pruned_count int;
begin
  delete from oban_jobs outer_jobs
  where outer_jobs.id in (
    select id
    from oban_jobs inner_jobs
    where inner_jobs.state in ('completed', 'cancelled', 'discarded')
      and (
        inner_jobs.attempted_at < now() - (opts->>'interval')::interval
        or
        inner_jobs.cancelled_at < now() - (opts->>'interval')::interval
      )
  );

  get diagnostics pruned_count = row_count;

  raise info 'pruned % jobs', pruned_count;
end $proc$
language plpgsql
set search_path from current;
