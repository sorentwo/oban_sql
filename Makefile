OUTPUT := dst/oban.sql

.PHONY: deps
deps:
	git clone https://github.com/theory/pgtap.git
	cd pgtap
	make
	make install
	make installcheck

# Testing

.PHONY: test_delete
test_delete:
	@ dropdb oban_sql_test
	@ echo "==> Oban test database dropped"

.PHONY: test_create
test_create:
	@ createdb oban_sql_test
	@ psql oban_sql_test -X --quiet -c 'CREATE EXTENSION pgtap;'
	@ echo "==> Oban test database created"

.PHONY: test_install
test_install: compile
	@ psql oban_sql_test -X --quiet -f $(OUTPUT)
	@ echo "==> Oban installed in test database"

.PHONY: test_reset
test_reset: test_delete test_create test_install

# Compilation

SQL_FILES = sql/boot/oban_boot_prefix.sql \
						$(wildcard sql/*.sql) \
						$(wildcard sql/migrations/*.sql) \
						sql/boot/oban_boot_migrate.sql \
						$(wildcard sql/consumers/*.sql) \
						$(wildcard sql/jobs/*.sql) \
						$(wildcard sql/plugins/*.sql) \
						sql/boot/oban_boot_suffix.sql

compile: $(SQL_FILES)
	@ mkdir -p dst
	@ cat $(SQL_FILES) > $(OUTPUT)
	@ echo "==> Oban compiled";

.PHONY: clean
clean:
	rm -rf dst
