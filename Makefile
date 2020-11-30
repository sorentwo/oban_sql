OUTPUT := dst/oban.sql
TEST_DB := oban_sql_test

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
	@ dropdb $(TEST_DB)
	@ echo "==> Oban test database dropped"

.PHONY: test_create
test_create:
	@ createdb $(TEST_DB)
	@ psql $(TEST_DB) -X --quiet -c 'CREATE EXTENSION pgtap;'
	@ echo "==> Oban test database created"

.PHONY: test_install
test_install: compile
	@ psql $(TEST_DB) -X --quiet -f $(OUTPUT)
	@ echo "==> Oban installed in test database"

.PHONY: test_reset
test_reset: test_delete test_create test_install

.PHONY: test
test: test_reset
	@ echo "==> Running tests..."
	@ psql -d $(TEST_DB) -Xf test/oban_test.sql

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
