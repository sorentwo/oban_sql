\unset ECHO
\set QUIET 1

\pset format unaligned
\pset tuples_only true
\pset pager off

\set ON_ERROR_ROLLBACK 1
\set ON_ERROR_STOP true

\ir oban_installation_test.sql
\ir oban_migration_test.sql
\ir consumers/oban_insert_consumer_test.sql
\ir consumers/oban_keepalive_consumer_test.sql
\ir consumers/oban_update_consumer_test.sql
\ir jobs/oban_ack_job_test.sql
\ir jobs/oban_discard_job_test.sql
\ir jobs/oban_error_job_test.sql
\ir jobs/oban_fetch_jobs_test.sql
\ir jobs/oban_insert_job_test.sql
\ir jobs/oban_retry_job_test.sql

select * from runtests('^oban_.+_test');
