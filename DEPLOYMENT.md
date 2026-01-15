# ElectricPlan Deployment Guide

This guide walks you through deploying the ElectricPlan application to production using Docker.

## Overview

ElectricPlan uses an automated CI/CD pipeline:
1. **Push to GitHub** → Triggers GitHub Actions
2. **Build Docker Image** → Automatically builds production image
3. **Push to Registry** → Stores image in GitHub Container Registry (ghcr.io)
4. **Deploy** → Pull and run the Docker container on your server

## Prerequisites

### Required
- **Production Server**: Linux server with Docker installed
- **GitHub Repository**: Code pushed to GitHub
- **Domain Name**: Optional, for SSL/HTTPS
- **Persistent Storage**: Docker volume for SQLite database files

### Access Requirements
- SSH access to production server
- GitHub account with repository access

## Step 1: Understand SQLite Storage

ElectricPlan uses **SQLite** for all databases. SQLite stores data in files located in the `storage/` directory:
- `storage/production.sqlite3` - Main application data
- `storage/production_cache.sqlite3` - Rails cache
- `storage/production_queue.sqlite3` - Background jobs (Solid Queue)
- `storage/production_cable.sqlite3` - WebSocket connections (Solid Cable)

**CRITICAL**: You MUST use a Docker volume to persist these database files across container restarts. Without a volume, all data will be lost when the container stops.

## Step 2: Configure Repository Settings

### Enable GitHub Container Registry

The Docker image will be automatically pushed to GitHub Container Registry (ghcr.io) when you push to main.

**No additional configuration needed** - GitHub Actions uses the built-in `GITHUB_TOKEN` automatically.

### Verify Workflow File

The deployment workflow is already configured in `.github/workflows/deploy.yml`. It will:
- Trigger on every push to `main` branch
- Build the Docker image
- Push to `ghcr.io/<your-username>/electric_plan:latest`

## Step 3: Prepare Environment Variables

Create a `.env.production` file on your production server:

```bash
# On your production server, create the environment file:
cat > ~/.electric_plan.env <<EOF
RAILS_MASTER_KEY=<value from config/master.key>
SOLID_QUEUE_IN_PUMA=true
EOF

# Secure the file
chmod 600 ~/.electric_plan.env
```

**Important**: Never commit this file to git. Keep it secure on your server only.

**Note**: No database credentials needed - SQLite uses file-based storage.

## Step 4: Initial Deployment

### On your production server:
```bash
# 1. Login to GitHub Container Registry
# Create a Personal Access Token at: https://github.com/settings/tokens/new?scopes=read:packages
echo "<YOUR-GITHUB-PAT>" | docker login ghcr.io -u <YOUR-USERNAME> --password-stdin

# 2. Pull the latest image
docker pull ghcr.io/<YOUR-USERNAME>/electric_plan:latest

# 3. Run the container
docker run -d \
  --name electric_plan \
  --restart unless-stopped \
  -p 3000:80 \
  --env-file ~/.electric_plan.env \
  -v electric_plan_storage:/rails/storage \
  ghcr.io/<YOUR-USERNAME>/electric_plan:latest

# 4. Run migrations
docker exec electric_plan rails db:migrate

# 5. Load seed data (compliance rules)
docker exec electric_plan rails db:seed
```

### Setup Reverse Proxy (Recommended)

Put a reverse proxy in front of the container for SSL/HTTPS. Here are two options:

#### Option A: Nginx with Let's Encrypt

```nginx
# /etc/nginx/sites-available/electric_plan
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Then use Certbot for SSL:
```bash
sudo certbot --nginx -d your-domain.com
```

#### Option B: Caddy (Automatic HTTPS)

```caddyfile
# /etc/caddy/Caddyfile
your-domain.com {
    reverse_proxy localhost:3000
}
```

Caddy automatically handles SSL certificates!

## Step 5: Verify Deployment

1. **Check application is running**:
   ```bash
   # Using Kamal
   bin/kamal app logs

   # Or Docker directly
   docker logs electric_plan
   ```

2. **Access the application**:
   - Open your browser to `http://<YOUR-SERVER-IP>` or `https://<YOUR-DOMAIN>`
   - You should see the ElectricPlan homepage

3. **Verify database connectivity**:
   ```bash
   # Using Kamal
   bin/kamal console

   # Or Docker directly
   docker exec -it electric_plan rails console
   ```

   In the console:
   ```ruby
   ActiveRecord::Base.connection.active?  # Should return true
   Dwelling.count  # Should show your data
   ```

## Step 6: Ongoing Deployments

### Automated Process

1. **Make code changes** locally
2. **Commit and push** to the `main` branch:
   ```bash
   git add .
   git commit -m "Your changes"
   git push origin main
   ```
3. **Wait for GitHub Actions** to build (check the Actions tab - usually 2-5 minutes)
4. **Deploy the new image on your server**:
   ```bash
   # Pull the latest image
   docker pull ghcr.io/<YOUR-USERNAME>/electric_plan:latest

   # Stop and remove old container
   docker stop electric_plan
   docker rm electric_plan

   # Start new container (same command as initial deployment)
   docker run -d \
     --name electric_plan \
     --restart unless-stopped \
     -p 3000:80 \
     --env-file ~/.electric_plan.env \
     -v electric_plan_storage:/rails/storage \
     ghcr.io/<YOUR-USERNAME>/electric_plan:latest

   # Run any new migrations
   docker exec electric_plan rails db:migrate
   ```

### Deployment Script (Optional)

Create a deployment script on your server to automate this:

```bash
#!/bin/bash
# ~/deploy_electric_plan.sh

echo "Pulling latest image..."
docker pull ghcr.io/<YOUR-USERNAME>/electric_plan:latest

echo "Stopping old container..."
docker stop electric_plan
docker rm electric_plan

echo "Starting new container..."
docker run -d \
  --name electric_plan \
  --restart unless-stopped \
  -p 3000:80 \
  --env-file ~/.electric_plan.env \
  -v electric_plan_storage:/rails/storage \
  ghcr.io/<YOUR-USERNAME>/electric_plan:latest

echo "Running migrations..."
docker exec electric_plan rails db:migrate

echo "Deployment complete!"
docker logs --tail 50 electric_plan
```

Make it executable:
```bash
chmod +x ~/deploy_electric_plan.sh
```

Then deploy with:
```bash
~/deploy_electric_plan.sh
```

### Rollback

If something goes wrong, use a specific commit SHA:

```bash
# List available tags
docker images ghcr.io/<YOUR-USERNAME>/electric_plan

# Pull a specific version
docker pull ghcr.io/<YOUR-USERNAME>/electric_plan:main-<COMMIT-SHA>

# Use it in your docker run command
docker run -d \
  --name electric_plan \
  --restart unless-stopped \
  -p 3000:80 \
  --env-file ~/.electric_plan.env \
  -v electric_plan_storage:/rails/storage \
  ghcr.io/<YOUR-USERNAME>/electric_plan:main-<COMMIT-SHA>
```

## Maintenance Commands

### View Logs
```bash
# Follow logs in real-time
docker logs -f electric_plan

# View last 100 lines
docker logs --tail 100 electric_plan

# View logs with timestamps
docker logs --timestamps electric_plan
```

### Access Rails Console
```bash
docker exec -it electric_plan rails console
```

### Database Console
```bash
docker exec -it electric_plan rails dbconsole
```

### Run Database Migrations
```bash
docker exec electric_plan rails db:migrate
```

### Restart Application
```bash
docker restart electric_plan
```

### Check Container Status
```bash
# View running containers
docker ps

# View container resource usage
docker stats electric_plan

# Inspect container details
docker inspect electric_plan
```

### Access Container Shell
```bash
docker exec -it electric_plan bash
```

## Troubleshooting

### Image Pull Failed
**Problem**: Cannot pull image from ghcr.io

**Solution**:
1. Verify the image exists: Visit `https://github.com/<USERNAME>/electric_plan/pkgs/container/electric_plan`
2. Check GitHub Actions completed successfully
3. Ensure your Personal Access Token has `read:packages` permission
4. Make package public: Go to package settings → Change visibility → Public

### Database Connection Failed
**Problem**: Application cannot access SQLite database

**Solution**:
1. Verify the Docker volume is mounted correctly:
   ```bash
   docker inspect electric_plan | grep -A 10 Mounts
   ```
2. Check storage directory permissions inside container:
   ```bash
   docker exec electric_plan ls -la /rails/storage
   ```
3. Ensure database files exist:
   ```bash
   docker exec electric_plan ls -la /rails/storage/*.sqlite3
   ```
4. If files are missing, run migrations:
   ```bash
   docker exec electric_plan rails db:migrate
   ```

### SSL Certificate Issues
**Problem**: HTTPS not working

**Solution**:
1. Ensure domain DNS points to your server
2. Check port 80 and 443 are open
3. Verify reverse proxy (Nginx/Caddy) is running
4. Check reverse proxy logs:
   ```bash
   # Nginx
   sudo tail -f /var/log/nginx/error.log

   # Caddy
   sudo journalctl -u caddy -f
   ```

### Application Crashes
**Problem**: Container keeps restarting

**Solution**:
1. Check logs for error messages:
   ```bash
   bin/kamal app logs
   ```
2. Verify RAILS_MASTER_KEY is correct
3. Check database migrations are up to date:
   ```bash
   bin/kamal app exec 'rails db:migrate:status'
   ```
4. Ensure all environment variables are set

## Security Checklist

- [ ] `config/master.key` is never committed to git
- [ ] `.env.production` is never committed to git
- [ ] GitHub Personal Access Token has minimal required permissions
- [ ] SSL/TLS is enabled (HTTPS)
- [ ] Server firewall is configured (only allow 22, 80, 443)
- [ ] Docker volume backups are scheduled (SQLite database files)
- [ ] Storage directory has proper permissions

## Backup Strategy

### Database Backups

Create automated SQLite backups. SQLite databases are just files, so backing them up is straightforward:

```bash
# Backup all SQLite databases from the Docker volume
docker run --rm -v electric_plan_storage:/data -v $(pwd):/backup \
  alpine sh -c "cd /data && tar czf /backup/sqlite_backup_$(date +%Y%m%d_%H%M%S).tar.gz *.sqlite3"

# Or copy individual database files
docker cp electric_plan:/rails/storage/production.sqlite3 \
  ./backup_production_$(date +%Y%m%d_%H%M%S).sqlite3
```

**Schedule with cron:**
```bash
# Add to crontab (crontab -e)
0 2 * * * docker run --rm -v electric_plan_storage:/data -v /backups:/backup alpine sh -c "cd /data && tar czf /backup/sqlite_backup_\$(date +\%Y\%m\%d_\%H\%M\%S).tar.gz *.sqlite3"
```

### Storage Backups

The Docker volume `electric_plan_storage` contains uploaded files:

```bash
# Backup storage volume
docker run --rm -v electric_plan_storage:/data -v $(pwd):/backup \
  alpine tar czf /backup/storage_backup_$(date +%Y%m%d_%H%M%S).tar.gz /data
```

## Support

For issues or questions:
- Check application logs
- Review Rails logs: `bin/kamal app logs`
- Consult CLAUDE.md for application architecture details
- Check GitHub Actions for build failures
