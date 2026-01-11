# ElectricPlan

A Ruby on Rails application configured for Docker deployment.

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

- **Development**: MySQL 8.0 (runs in Docker container)
- **Test**: SQLite3
- **Production**: MySQL (connects to existing database via environment variables)

### Production Environment Variables

Set these environment variables in your production environment:

- `DATABASE_HOST` - MySQL server host
- `DATABASE_NAME` - Primary database name
- `DATABASE_USER` - MySQL username
- `DATABASE_PASSWORD` - MySQL password
- `DATABASE_CACHE_NAME` - Cache database name (optional)
- `DATABASE_QUEUE_NAME` - Queue database name (optional)
- `DATABASE_CABLE_NAME` - Cable database name (optional)
- `RAILS_MASTER_KEY` - Rails master key for encrypted credentials

## Production Deployment

### Building for Production

```bash
docker build -t electric_plan .
```

### Running in Production

```bash
docker run -d -p 80:80 \
  -e DATABASE_HOST=your-mysql-host \
  -e DATABASE_NAME=your-database-name \
  -e DATABASE_USER=your-username \
  -e DATABASE_PASSWORD=your-password \
  -e RAILS_MASTER_KEY=your-master-key \
  --name electric_plan electric_plan
```

## Ruby Version

- Ruby 3.3.6
- Rails 8.0.0

## System Dependencies

All dependencies are managed through Docker containers.
