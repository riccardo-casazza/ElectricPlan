# GitHub Actions Workflows

This directory contains automated CI/CD workflows for ElectricPlan.

## Workflows

### 1. CI Pipeline (`ci.yml`)

Runs on every push and pull request to the `main` branch.

**Jobs:**

#### Test
- Sets up Ruby 3.3.6
- Installs SQLite3 dependencies
- Creates and migrates test database
- **Runs compliance tests** using `test_compliance_manual.rb`
- Runs Brakeman security scan

#### Lint
- Runs RuboCop for code style checking
- Executes in parallel for faster feedback

#### Build
- Builds Docker image to verify it compiles
- Uses GitHub Actions cache for faster builds
- Does not push the image (test only)

#### Security
- Runs Brakeman security scanner
- Uploads security report as artifact
- Fails if security warnings are found

**Environment Variables:**
- `RAILS_ENV=test`

### 2. Deploy Pipeline (`deploy.yml`)

Runs on every push to the `main` branch.

**Jobs:**

#### Build and Push
- Builds production Docker image
- Pushes to GitHub Container Registry (ghcr.io)
- Tags with:
  - `latest` - Always points to latest main
  - `main-<sha>` - Specific commit for rollback
  - `main` - Latest from main branch

**Image Location:**
```
ghcr.io/<your-username>/electric_plan:latest
```

## Status Badges

Add these to your README.md:

```markdown
![CI](https://github.com/<username>/ElectricPlan/workflows/CI/badge.svg)
![Deploy](https://github.com/<username>/ElectricPlan/workflows/Build%20and%20Push%20Docker%20Image/badge.svg)
```

## Local Testing

To run the same tests locally:

```bash
# Run compliance tests
ruby test_compliance_manual.rb

# Run security scan
bundle exec brakeman -q -w2

# Run linter
bundle exec rubocop --parallel

# Build Docker image
docker build -t electric_plan:test .
```

## Test Coverage

### Compliance Tests

The CI runs 10 essential compliance rule tests covering:

- ✅ Light breaker rules (exclusive type, max count, max current)
- ✅ Socket breaker rules (exclusive type for kitchen)
- ✅ Convector rules (cable section, max power)
- ✅ System rules (min circuits for lights, shutters, appliances)

See `test/services/README.md` for full details on the 33 rules.

### Known Limitations

Due to a Rails 8.0.4 + Minitest 6.0.1 compatibility issue, we use a manual test script (`test_compliance_manual.rb`) instead of the standard `rails test` command.

This will be updated once the Rails issue is resolved: https://github.com/rails/rails/issues/53790

## Troubleshooting

### Failed CI Tests

If CI tests fail:

1. **Check the compliance tests output** - Look for which rules are failing
2. **Run locally** - `ruby test_compliance_manual.rb`
3. **Check database seed** - Ensure `rails db:seed` ran successfully
4. **Review recent changes** - Did you modify compliance rules or engine?

### Failed Security Scan

If Brakeman reports security issues:

1. **Review the report** - Download the artifact from GitHub Actions
2. **Check severity** - High and medium warnings should be addressed
3. **False positives** - Add to `.brakeman.ignore` if needed
4. **Fix vulnerabilities** - Update dependencies or refactor code

### Failed Linter

If RuboCop fails:

1. **Run locally** - `bundle exec rubocop`
2. **Auto-fix** - `bundle exec rubocop -a`
3. **Review changes** - Ensure auto-fixes are correct
4. **Disable rules** - Only if absolutely necessary in `.rubocop.yml`

## Adding New Tests

To add new compliance tests to CI:

1. Add test to `test_compliance_manual.rb`
2. Verify locally: `ruby test_compliance_manual.rb`
3. Push to GitHub
4. CI will automatically run the new tests

## Deployment

The deploy workflow automatically builds and pushes Docker images when you push to `main`.

To deploy the image:

```bash
# Pull latest image
docker pull ghcr.io/<username>/electric_plan:latest

# Run with environment variables
docker run -d \
  --name electric_plan \
  -p 3000:80 \
  --env-file .env \
  ghcr.io/<username>/electric_plan:latest
```

See `CLAUDE.md` for full deployment instructions.
