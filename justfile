# ElectricPlan development tasks

# Default recipe - show available commands
default:
    @just --list

# Install dependencies and setup database
setup:
    bundle install
    bundle exec rails db:create db:migrate db:seed

# Start development server
dev:
    bin/dev

# Run compliance tests (used by CI)
test:
    bundle exec ruby test_compliance_manual.rb

# Run full test suite
test-full:
    bundle exec rails test test/services/compliance_engine_test.rb

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
    bundle exec rails db:migrate

# Reset database
db-reset:
    bundle exec rails db:reset

# Open Rails console
console:
    bundle exec rails console

# Sync production database to local development
# Usage: just sync-db server0@server0:~/configuration/electricplan
sync-db remote_path:
    scp {{remote_path}}/production.sqlite3 storage/development.sqlite3
    scp {{remote_path}}/production_cache.sqlite3 storage/development_cache.sqlite3
    scp {{remote_path}}/production_queue.sqlite3 storage/development_queue.sqlite3
    scp {{remote_path}}/production_cable.sqlite3 storage/development_cable.sqlite3
    @echo "Database synced from production. Run 'just dev' to start server."

# Run CI pipeline in Docker (no local Ruby needed)
ci:
    docker build -t electricplan:ci --target build .
    docker run --rm electricplan:ci bundle exec ruby test_compliance_manual.rb
    docker run --rm electricplan:ci bundle exec brakeman -q -w2
    docker run --rm electricplan:ci bundle exec rubocop
