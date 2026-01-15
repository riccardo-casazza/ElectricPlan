# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ElectricPlan is a Ruby on Rails 8.0.0 application configured for Docker deployment using SQLite3.

## Database Architecture

This application uses **SQLite3** for all environments:

- **Development**: SQLite3 (file-based at `storage/development.sqlite3`)
- **Test**: SQLite3 (file-based at `storage/test.sqlite3`)
- **Production**: SQLite3 (file-based at `storage/production.sqlite3`)

The application uses separate SQLite databases for different concerns:
  - Primary database (main application data)
  - Cache database (for Solid Cache)
  - Queue database (for Solid Queue)
  - Cable database (for Solid Cable)

See `config/database.yml` for the full configuration.

**Important**: SQLite database files are stored in the `storage/` directory. In production, ensure this directory is persisted using Docker volumes or your hosting platform's storage solution.

## Rails Solid Stack

This application uses Rails' modern "Solid" stack for infrastructure:

- **Solid Cache**: Database-backed cache store (replaces Redis/Memcached)
  - Configuration: `config/cache.yml`
  - Schema: `db/cache_schema.rb`
  - Migrations: `db/cache_migrate/`

- **Solid Queue**: Database-backed job queue (replaces Sidekiq/Resque)
  - Configuration: `config/queue.yml`
  - Schema: `db/queue_schema.rb`
  - Migrations: `db/queue_migrate/`
  - In production, runs inside Puma process via `SOLID_QUEUE_IN_PUMA=true`

- **Solid Cable**: Database-backed Action Cable (replaces Redis for WebSockets)
  - Configuration: `config/cable.yml`
  - Schema: `db/cable_schema.rb`
  - Migrations: `db/cable_migrate/`

## Development Commands

### Local Development

Uses SQLite3 (no additional database server required).

```bash
# Install dependencies
bundle install

# Setup database
rails db:create db:migrate

# Start server
rails server
# or
bin/dev

# Run tests
rails test

# Run specific test
rails test test/models/your_model_test.rb
```

## Frontend Architecture

- **Asset Pipeline**: Propshaft (modern replacement for Sprockets)
- **JavaScript**: Import maps (no Node.js/npm required)
- **Frameworks**: Hotwire (Turbo + Stimulus)
  - Turbo controllers in `app/javascript/controllers/`
  - Entry point: `app/javascript/application.js`
  - Import map configuration: `config/importmap.rb`

## Deployment

### GitHub Actions Automated Build

The application automatically builds and pushes a Docker image to GitHub Container Registry (ghcr.io) when code is pushed to the `main` branch.

**Workflow**: `.github/workflows/deploy.yml`

**What happens on push to main:**
1. GitHub Actions checks out the code
2. Builds the Docker image using the production Dockerfile
3. Pushes the image to `ghcr.io/YOUR_USERNAME/electric_plan` with tags:
   - `latest` - Always points to the most recent main branch build
   - `main-<git-sha>` - Specific commit for rollback capability
   - `main` - Latest from main branch

**Docker Image Location:**
```
ghcr.io/<your-github-username>/electric_plan:latest
```

### Docker Deployment

Pull and run the pre-built image from GitHub Container Registry:

```bash
# 1. Create environment file on your server
cat > ~/.electric_plan.env <<EOF
RAILS_MASTER_KEY=<value from config/master.key>
SOLID_QUEUE_IN_PUMA=true
EOF
chmod 600 ~/.electric_plan.env

# 2. Login to GitHub Container Registry
echo "<YOUR-GITHUB-PAT>" | docker login ghcr.io -u <YOUR-USERNAME> --password-stdin

# 3. Pull and run
docker pull ghcr.io/<your-github-username>/electric_plan:latest

docker run -d \
  --name electric_plan \
  --restart unless-stopped \
  -p 3000:80 \
  --env-file ~/.electric_plan.env \
  -v electric_plan_storage:/rails/storage \
  ghcr.io/<your-github-username>/electric_plan:latest

# 4. Run migrations
docker exec electric_plan rails db:migrate db:seed
```

**Important Notes:**
- SQLite database files are stored in `/rails/storage` inside the container
- The volume `electric_plan_storage` persists the database across container restarts
- **Reverse Proxy:** Use Nginx or Caddy in front of the container for SSL/HTTPS

### Cloud Platform Deployment

The Docker image can also be deployed to cloud platforms:
- **Google Cloud Run**: Deploy directly from ghcr.io (ensure persistent volume for /rails/storage)
- **AWS ECS/Fargate**: Use the ghcr.io image with EFS for persistent storage
- **Azure Container Instances**: Pull from ghcr.io with Azure File Share
- **DigitalOcean App Platform**: Connect to GitHub Container Registry with persistent volumes
- **Fly.io**: Deploy using `flyctl` with Fly Volumes for database persistence

**Critical**: All platforms must provide persistent storage for the `/rails/storage` directory to preserve the SQLite database.

### Required Environment Variables for Production

All deployment options require these environment variables:

**Required:**
- `RAILS_MASTER_KEY` - From `config/master.key` (keep secret!)

**Optional (with defaults):**
- `SOLID_QUEUE_IN_PUMA` - Defaults to `true` (runs background jobs in web server)

### Pre-Deployment Checklist

Before deploying to production:

1. **Persistent Storage**: Ensure `/rails/storage` is backed by a persistent volume

2. **Run Migrations**: After first deployment:
   ```bash
   docker exec electric_plan rails db:migrate
   ```

3. **Seed Data**: Load initial compliance rules:
   ```bash
   docker exec electric_plan rails db:seed
   ```

4. **SSL/TLS**: Configure reverse proxy (Nginx with Certbot, or Caddy for automatic HTTPS)

5. **Backups**: Set up regular backups of the `storage/` directory containing SQLite databases

## Testing

- Test framework: Minitest (Rails default)
- System tests: Capybara + Selenium WebDriver
- Test database: SQLite3 (`storage/test.sqlite3`)
- Test helper: `test/test_helper.rb`
- System test base: `test/application_system_test_case.rb`

## CRUD Page Ergonomics Guidelines

When creating or modifying CRUD pages, follow these standards for consistency and usability:

### Index Pages (List View)

**Required Elements:**
- Table layout with clear column headers (not individual card-style items)
- "Back to Home" navigation link at the top
- "New [Resource]" button prominently displayed above the table
- Actions column with inline Edit and Delete buttons
- Empty state message when no records exist
- For parent resources (e.g., Floors), show count of associated children (e.g., number of rooms)

**Example Structure:**
```erb
<div style="margin-bottom: 1rem;">
  <%= link_to "← Back to Home", root_path %>
</div>

<h1>[Resources]</h1>

<div style="margin: 1.5rem 0;">
  <%= link_to "New [Resource]", new_resource_path, class: "button-primary" %>
</div>

<table class="crud-table">
  <thead>
    <tr>
      <th>Column 1</th>
      <th>Column 2</th>
      <th>Actions</th>
    </tr>
  </thead>
  <tbody>
    <% @resources.each do |resource| %>
      <tr>
        <td><%= resource.attribute %></td>
        <td><%= resource.other_attribute %></td>
        <td class="actions">
          <%= link_to "Show", resource, class: "button-small" %>
          <%= link_to "Edit", edit_resource_path(resource), class: "button-small button-secondary" %>
          <%= button_to "Delete", resource, method: :delete, class: "button-small button-danger", form: { data: { turbo_confirm: "Are you sure?" } } %>
        </td>
      </tr>
    <% end %>
  </tbody>
</table>

<% if @resources.empty? %>
  <p style="margin-top: 2rem; color: #666;">No [resources] yet. Click "New [Resource]" to add one.</p>
<% end %>
```

### Show Pages (Detail View)

**Required Elements:**
- "Back to [Resources]" navigation link at the top
- Page title (e.g., "Floor Details")
- Render the resource partial for displaying data
- Edit and Delete buttons at the bottom with proper styling and confirmation

**Example Structure:**
```erb
<div style="margin-bottom: 1rem;">
  <%= link_to "← Back to [Resources]", resources_path %>
</div>

<h1>[Resource] Details</h1>

<%= render @resource %>

<div style="margin-top: 2rem;">
  <%= link_to "Edit", edit_resource_path(@resource), class: "button-secondary" %>
  <%= button_to "Delete", @resource, method: :delete, class: "button-danger", form: { data: { turbo_confirm: "Are you sure?" } } %>
</div>
```

### New/Edit Pages (Form Pages)

**Required Elements:**
- "Back to [Resources]" navigation link at the top
- Clear page title ("New [Resource]" or "Edit [Resource]")
- Form with proper styling classes
- Cancel button that links back to index
- Submit button with primary styling

**Example Structure:**
```erb
<div style="margin-bottom: 1rem;">
  <%= link_to "← Back to [Resources]", resources_path %>
</div>

<h1>New [Resource]</h1>  <!-- or "Edit [Resource]" -->

<%= render "form", resource: @resource %>
```

### Form Partials

**Required Elements:**
- Form wrapper with `crud-form` class
- Error messages display with proper styling
- Form fields wrapped in `form-field` class
- Labels without inline styles
- Inputs with `form-input` class
- Form actions section with Submit and Cancel buttons

**Example Structure:**
```erb
<%= form_with(model: resource, class: "crud-form") do |form| %>
  <% if resource.errors.any? %>
    <div class="error-messages">
      <h3><%= pluralize(resource.errors.count, "error") %> prohibited this [resource] from being saved:</h3>
      <ul>
        <% resource.errors.each do |error| %>
          <li><%= error.full_message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div class="form-field">
    <%= form.label :attribute %>
    <%= form.text_field :attribute, class: "form-input" %>
  </div>

  <div class="form-field">
    <%= form.label :association_id, "Association Name" %>
    <%= form.collection_select :association_id, Association.all, :id, :name,
        { prompt: "Select an association" }, { class: "form-input" } %>
  </div>

  <div class="form-actions">
    <%= form.submit class: "button-primary" %>
    <%= link_to "Cancel", resources_path, class: "button-secondary" %>
  </div>
<% end %>
```

### Delete Confirmations

**Always use `data-turbo-confirm` for delete actions:**
- For resources with associations: "Are you sure you want to delete this [resource] and all its [associated resources]?"
- For simple resources: "Are you sure you want to delete this [resource]?"

### CSS Classes Reference

All CRUD styling is defined in `app/assets/stylesheets/application.css`:

**Button Classes:**
- `button-primary` - Blue button for primary actions (Create, Submit)
- `button-secondary` - Gray button for secondary actions (Edit, Cancel)
- `button-danger` - Red button for destructive actions (Delete)
- `button-small` - Smaller buttons for table actions

**Table Classes:**
- `crud-table` - Main table wrapper
- `.actions` - Actions column in tables

**Form Classes:**
- `crud-form` - Form wrapper
- `form-field` - Individual field wrapper
- `form-input` - Input/select fields
- `form-actions` - Submit/Cancel button container
- `error-messages` - Error display container

### Model Associations

When creating resources with `belongs_to` associations:
- Use `rails generate scaffold Resource name:string parent:references`
- This automatically creates the foreign key and `belongs_to` association
- Update the parent model with `has_many :resources, dependent: :destroy`
- Use `collection_select` in forms for better UX than text fields

### Scaffold Command Pattern

```bash
# Simple resource
rails generate scaffold Resource name:string

# Resource with association
rails generate scaffold Resource name:string parent:references

# Always run migrations after
rails db:migrate
```

## Key Files

- `config/database.yml` - SQLite database configuration for all environments
- `Dockerfile` - Production-ready multi-stage build
- `bin/dev` - Development server startup script
- `app/assets/stylesheets/application.css` - All CRUD styling and UI components
- `config/compliance_rules.yml` - All 33 electrical compliance rules
- `app/services/compliance_engine.rb` - Compliance validation engine
