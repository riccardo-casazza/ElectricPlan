# ElectricPlan

![CI Status](https://github.com/YOUR_USERNAME/ElectricPlan/workflows/CI/badge.svg)
![Deploy Status](https://github.com/YOUR_USERNAME/ElectricPlan/workflows/Build%20and%20Push%20Docker%20Image/badge.svg)

A Ruby on Rails application for electrical installation compliance management against the French NF C 15-100 standard.

## Requirements

- Ruby 3.3.6
- [just](https://github.com/casey/just) command runner
- SQLite3

## Quick Start

```bash
# Install just (macOS)
brew install just

# Install just (Linux)
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin

# Setup the project
just setup

# Start development server
just dev
```

## Available Commands

Run `just` to see all available commands:

```bash
just              # Show available commands
just setup        # Install dependencies and setup database
just dev          # Start development server
just test         # Run compliance tests
just test-full    # Run full test suite
just security     # Run Brakeman security scan
just lint         # Run RuboCop linter
just lint-fix     # Auto-fix lint issues
just migrate      # Run database migrations
just db-reset     # Reset database
just console      # Open Rails console
just sync-db      # Sync production database to local
```

## Development Workflow

### Running Tests

```bash
just test         # Run compliance tests (CI uses this)
just test-full    # Run full Rails test suite
```

### Code Quality

```bash
just lint         # Check code style
just lint-fix     # Auto-fix code style issues
just security     # Run security scan
```

### Database Operations

```bash
just setup        # Initial database setup
just migrate      # Run pending migrations
just db-reset     # Reset and reseed database
just console      # Open Rails console
```

### Syncing Production Database

```bash
# With custom remote path
just sync-db "server0@server0:~/configuration/electricplan"

# With default server path
just sync-db-default
```

## Docker Deployment

### Building for Production

```bash
docker build -t electric_plan .
```

### Running in Production

```bash
docker run -d -p 80:80 \
  -e RAILS_MASTER_KEY=your-master-key \
  -v electric_plan_storage:/rails/storage \
  --name electric_plan electric_plan
```

**Note:** Use a volume to persist the SQLite database across container restarts.

## Database

- **All Environments**: SQLite3 (file-based)
- **Development**: `storage/development.sqlite3`
- **Test**: `storage/test.sqlite3`
- **Production**: `storage/production.sqlite3`

## Documentation

- **[CLAUDE.md](CLAUDE.md)** - Domain model and compliance engine architecture
- **[TESTING.md](TESTING.md)** - Testing guide and CI configuration
- **[test/services/README.md](test/services/README.md)** - Compliance test documentation
