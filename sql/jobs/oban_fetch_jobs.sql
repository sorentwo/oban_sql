create or replace function oban_fetch_jobs(consumer_id uuid)
returns setof oban_jobs as $func$
declare
  demand int;
  cons_queue text;
begin
  select (meta->'limit')::int - coalesce(array_length(consumed_ids, 1), 0),
         cons.queue
  from oban_consumers as cons
  where cons.id = consumer_id
  limit 1
  into demand, cons_queue;

  return query with updated_jobs as (
    update oban_jobs
       set state = 'executing',
           attempted_at = utc_now(),
           attempt = attempt + 1
    where id in (
      select id
      from oban_jobs as jobs
      where jobs.state = 'available'
        and jobs.queue = cons_queue
      order by jobs.priority asc, jobs.scheduled_at asc, jobs.id desc
      limit demand
      for update skip locked
    )
    returning *
  ), updated_cons as (
    update oban_consumers as cons
       set consumed_ids = consumed_ids || array(select id from updated_jobs),
           updated_at = utc_now()
    where cons.id = consumer_id
  )
  select * from updated_jobs;
end $func$
language plpgsql
set search_path from current;
