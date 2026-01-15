# ElectricPlan

![CI Status](https://github.com/YOUR_USERNAME/ElectricPlan/workflows/CI/badge.svg)
![Deploy Status](https://github.com/YOUR_USERNAME/ElectricPlan/workflows/Build%20and%20Push%20Docker%20Image/badge.svg)

A Ruby on Rails application for electrical installation compliance management, configured for Docker deployment.

## Requirements

- Docker
- Docker Compose

## Getting Started with Docker

### Development Setup

1. Clone the repository
```bash
git clone <repository-url>
cd ElectricPlan
```

2. Build and start the containers
```bash
docker-compose up --build
```

3. Create the database
```bash
docker-compose exec web rails db:create
docker-compose exec web rails db:migrate
```

4. Access the application
Open your browser and navigate to `http://localhost:3000`

### Common Docker Commands

**Start the application**
```bash
docker-compose up
```

**Start in detached mode**
```bash
docker-compose up -d
```

**Stop the application**
```bash
docker-compose down
```

**View logs**
```bash
docker-compose logs -f web
```

**Access Rails console**
```bash
docker-compose exec web rails console
```

**Run migrations**
```bash
docker-compose exec web rails db:migrate
```

**Run tests**
```bash
# Compliance tests
docker-compose exec web ruby test_compliance_manual.rb

# Full test suite (when Rails/Minitest issue is fixed)
docker-compose exec web rails test
```

**Install new gems**
```bash
docker-compose exec web bundle install
docker-compose restart web
```

**Reset database**
```bash
docker-compose exec web rails db:reset
```

## Database Configuration

- **All Environments**: SQLite3 (file-based database)
- **Development**: `storage/development.sqlite3`
- **Test**: `storage/test.sqlite3`
- **Production**: `storage/production.sqlite3`

See [CLAUDE.md](CLAUDE.md) for detailed database architecture and deployment instructions.

## Production Deployment

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

## Ruby Version

- Ruby 3.3.6
- Rails 8.0.0

## System Dependencies

All dependencies are managed through Docker containers.

## Testing

ElectricPlan includes comprehensive compliance testing for electrical installation rules.

### Running Tests

```bash
# Run compliance tests (recommended)
ruby test_compliance_manual.rb

# Run security scan
bundle exec brakeman -q -w2

# Run code linter
bundle exec rubocop
```

See [TESTING.md](TESTING.md) for detailed testing documentation.

### Test Coverage

- **33 compliance rules** covering breakers, items, RCDs, and system-wide requirements
- Automated CI pipeline with GitHub Actions
- Security scanning with Brakeman
- Code quality checks with RuboCop

## Documentation

- **[CLAUDE.md](CLAUDE.md)** - Project overview and deployment guide
- **[TESTING.md](TESTING.md)** - Testing guide and CI configuration
- **[test/services/README.md](test/services/README.md)** - Compliance test documentation
- **[.github/workflows/README.md](.github/workflows/README.md)** - GitHub Actions workflow documentation
