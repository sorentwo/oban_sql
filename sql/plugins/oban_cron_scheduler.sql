--
-- Insert jobs according to a table pairing cron expressions and job data.
--
create or replace procedure oban_cron_scheduler(inout opts jsonb) as $proc$
declare
  entry jsonb;
  expr jsonb;
  meta jsonb;
  now timestamp;
  ins_loop_count int := 0;
  inserted_count int := 0;

  -- Make each job unique for 59 seconds to prevent double-enqueue if the loop restarts The
  -- minimum resolution for our cron jobs is 1 minute, so there is potentially a one second window
  -- where a double enqueue can happen.
  default_unique jsonb := '{"period": 59}';
begin
  now := timezone(coalesce(opts->>'timezone', 'utc'), now());

  for entry in select * from jsonb_array_elements(opts->'table') loop
    expr := oban_parse_cron(entry->>'expr');

    if oban_check_cron(expr, now) then
      meta := coalesce(entry#>'{opts,meta}', '{}');
      meta := jsonb_set(meta, '{unique}', default_unique);

      perform oban_insert_job(
        entry->>'queue',
        entry->>'worker',
        coalesce(entry#>'{opts,args}', '{}'),
        meta,
        coalesce(entry#>'{opts,priority}', '0')::int,
        coalesce(entry#>'{opts,max_attempts}', '20')::int
      );

      get diagnostics ins_loop_count := row_count;

      inserted_count := inserted_count + ins_loop_count;
    end if;
  end loop;

  raise info 'oban_cron_scheduler: inserted % jobs', inserted_count;
end $proc$
language plpgsql
set search_path from current;
