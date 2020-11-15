create or replace function oban_fetch_jobs(node text, name text, queue text, nonce text)
returns setof oban_jobs as $func$
declare
  demand int;
begin
  select (meta->'limit')::int - array_length(consumed_ids, 1)
  from oban_consumers as cons
  where cons.node = oban_fetch_jobs.node
    and cons.name = oban_fetch_jobs.name
    and cons.queue = oban_fetch_jobs.queue
    and cons.nonce = oban_fetch_jobs.nonce
  limit 1
  into demand;

  return query with updated_jobs as (
    update oban_jobs
       set state = 'executing',
           attempted_at = timezone('utc', now()),
           attempt = attempt + 1
    where id in (
      select id
      from oban_jobs as jobs
      where jobs.state = 'available'
        and jobs.queue = oban_fetch_jobs.queue
      order by jobs.priority asc, jobs.scheduled_at asc, jobs.id asc
      limit demand
      for update skip locked
    )
    returning *
  ), updated_cons as (
    update oban_consumers as cons
       set consumed_ids = consumed_ids || array(select id from updated_jobs),
           updated_at = timezone('utc', now())
    where cons.node = oban_fetch_jobs.node
      and cons.name = oban_fetch_jobs.name
      and cons.queue = oban_fetch_jobs.queue
      and cons.nonce = oban_fetch_jobs.nonce
  )
  select * from updated_jobs;
end $func$
language plpgsql
set search_path from current;
