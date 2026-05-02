# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ElectricPlan is a Ruby on Rails 8.0.0 application for managing electrical installation compliance. It validates residential electrical installations against the French **NF C 15-100** standard, checking breaker configurations, RCD requirements, cable sizing, and more.

## Development Commands

```bash
# Install dependencies and setup
bundle install
rails db:create db:migrate db:seed

# Start server
bin/dev

# Run tests
ruby test_compliance_manual.rb          # Compliance tests (CI uses this)
rails test test/services/compliance_engine_test.rb  # Full test suite (when fixed)

# Security and linting
bundle exec brakeman -q -w2             # Security scan
bundle exec rubocop                     # Code linting
bundle exec rubocop -a                  # Auto-fix lint issues
```

## Domain Model Hierarchy

The application models a complete electrical installation with this hierarchy:

```
Dwelling (building/house)
└── ElectricalPanel (tableau électrique)
    └── ResidualCurrentDevice (RCD/interrupteur différentiel)
        └── Breaker (disjoncteur)
            └── Item (electrical endpoint: light, socket, appliance)
                └── ItemType (categorization: light, socket, convector, etc.)
```

**Supporting models:**
- `Floor` → `Room` (physical location hierarchy)
- `Cable` (wire specifications with section in mm²)
- `ResidualCurrentDeviceType` (AC, A, F types for different loads)

## Compliance Engine Architecture

The core business logic is a rule-based compliance validation system:

**Key files:**
- `config/compliance_rules.yml` - 33 rules defined in YAML (breaker limits, cable sizing, RCD requirements)
- `app/services/compliance_engine.rb` - Rule evaluation engine
- `app/models/compliance_violation.rb` - Violation result objects
- `app/models/concerns/compliance_aware.rb` - Mixin for models (Breaker, RCD, Item, etc.)

**Rule structure (in YAML):**
```yaml
rule_name:
  applies_to: Breaker          # Target model
  condition:
    type: has_light_items      # When to check
  validation:
    type: max_count            # What to validate
    max_value: 8
  severity: error
  message: "..."               # Supports {placeholders}
  help: "..."
```

**Validation types:** `exclusive_type`, `max_count`, `max_attribute`, `min_cable_section`, `max_total_power`, `association_attribute`, `load_calculation`, `breaker_exclusive_for_type`

**Condition types:** `has_light_items`, `has_socket_items`, `socket_breaker_16a`, `socket_breaker_20a`, `kitchen_socket_breaker`, `has_convector_items`, `has_cooktop_items`, `item_type_equals`

## French Electrical Standards (NF C 15-100)

Key rules implemented:
- **Lights:** Max 8 per breaker, max 16A, min 1.5mm² cable
- **Sockets 16A:** Max 8, min 1.5mm² cable
- **Sockets 20A:** Max 12, min 2.5mm² cable
- **Kitchen sockets:** Max 6, min 2.5mm² cable
- **Appliances (dishwasher, washer, dryer, oven):** Dedicated circuits, max 20A, min 2.5mm²
- **Cooktop:** Dedicated, max 32A, min 6mm² cable, requires RCD type A
- **Convectors:** Dedicated, max 4500W total, max 20A, min 2.5mm²
- **RCD:** Max 8 breakers per RCD, load calculation rules
- **Surge protection:** Required based on AQ2 lightning zone (see `concerns/aq2_zone.rb`)

## Database

SQLite3 for all environments (files in `storage/` directory). Uses Rails Solid Stack:
- **Solid Cache** (`db/cache_schema.rb`)
- **Solid Queue** (`db/queue_schema.rb`)
- **Solid Cable** (`db/cable_schema.rb`)

## Frontend

- **Assets:** Propshaft
- **JavaScript:** Import maps (no Node.js required)
- **Frameworks:** Hotwire (Turbo + Stimulus)
- **Styling:** Custom CSS in `app/assets/stylesheets/application.css`

## CRUD Page Guidelines

Use consistent patterns for all CRUD views:

**CSS classes:**
- Buttons: `button-primary`, `button-secondary`, `button-danger`, `button-small`
- Tables: `crud-table`, `.actions`
- Forms: `crud-form`, `form-field`, `form-input`, `form-actions`

**Required elements:**
- Index: Table layout, "Back to Home" link, "New" button, Actions column
- Show: Back link, title, render partial, Edit/Delete buttons
- Forms: `crud-form` class, error display, Cancel button with `button-secondary`

**Delete confirmations:** Always use `data-turbo-confirm`

## Deployment

GitHub Actions (`.github/workflows/deploy.yml`) builds and pushes Docker images to ghcr.io on push to main.

**Required for production:**
- `RAILS_MASTER_KEY` environment variable
- Persistent volume for `/rails/storage` (SQLite databases)
- Run `rails db:migrate db:seed` after first deployment
