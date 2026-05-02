# ElectricPlan development tasks

# Default recipe - show available commands
default:
    @just --list

# Install dependencies and setup database
setup:
    bundle install
    rails db:create db:migrate db:seed

# Start development server
dev:
    bin/dev

# Run compliance tests (used by CI)
test:
    ruby test_compliance_manual.rb

# Run full test suite
test-full:
    rails test test/services/compliance_engine_test.rb

# Run security scan
security:
    bundle exec brakeman -q -w2

# Run code linter
lint:
    bundle exec rubocop

# Auto-fix lint issues
lint-fix:
    bundle exec rubocop -a

# Run migrations
migrate:
    rails db:migrate

# Reset database
db-reset:
    rails db:reset

# Open Rails console
console:
    rails console

# Sync production database to local development
# Usage: just sync-db server0@server0:~/configuration/electricplan
sync-db remote_path:
    scp {{remote_path}}/production.sqlite3 storage/development.sqlite3
    scp {{remote_path}}/production_cache.sqlite3 storage/development_cache.sqlite3
    scp {{remote_path}}/production_queue.sqlite3 storage/development_queue.sqlite3
    scp {{remote_path}}/production_cable.sqlite3 storage/development_cable.sqlite3
    @echo "Database synced from production. Run 'just dev' to start server."

# Sync production database (with default server path)
sync-db-default:
    just sync-db "server0@server0:~/configuration/electricplan"
