create or replace procedure oban_stage_scheduled(inout _opts json) as $proc$
declare
  staged_count int;
  queue text;
begin
  for queue in
    with updated as (
      update oban_jobs oj
      set state = 'available'
      where oj.state in ('scheduled', 'retryable') and oj.scheduled_at <= now()
      returning oj.queue
    ) select distinct(updated.queue) from updated
  loop
    perform oban_notify('oban_insert', json_build_object('queue', queue));
  end loop;

  get diagnostics staged_count = row_count;

  raise info 'staged % jobs', staged_count;
end $proc$
language plpgsql
set search_path from current;

