# Setup

.PHONY: deps
deps:
	git clone https://github.com/theory/pgtap.git
	cd pgtap
	make
	make install
	make installcheck

# Testing

.PHONY: test_setup
test_setup:
	createdb oban_sql_test
	psql oban_sql_test -c 'CREATE EXTENSION pgtap;'

.PHONY: test_delete
test_delete:
	dropdb oban_sql_test

.PHONY: test_reset
test_reset: test_delete test_setup

# Compilation

SQL_FILES = sql/boot/oban_boot_prefix.sql \
						$(wildcard sql/*.sql) \
						$(wildcard sql/migrations/*.sql) \
						sql/boot/oban_boot_migrate.sql \
						$(wildcard sql/consumers/*.sql) \
						$(wildcard sql/plugins/*.sql) \
						sql/boot/oban_boot_suffix.sql

compile: $(SQL_FILES)
	@ mkdir -p dst
	@ cat $(SQL_FILES) > dst/oban.sql
	@ echo "==> Oban compiled!";

.PHONY: clean
clean:
	rm -rf dst
