# Database Implementation for Kali-Docker Shared-Net

This directory contains sample implementation for adding a PostgreSQL database container to the Kali-Docker shared-net network.

## Files Overview

- `Dockerfile.postgres`: Dockerfile for PostgreSQL 15 Alpine-based container
- `init.sql`: Database initialization script with sample tables and data
- `postgresql.conf`: Custom PostgreSQL configuration optimized for development
- `docker-compose.postgres.yml`: Docker Compose snippet for database service

## Features

### Security
- Non-root user with limited privileges
- Password authentication required
- Internal network only (shared-net)
- Health checks for service monitoring

### Development Optimized
- Sample database and tables
- Development user credentials
- Relaxed PostgreSQL settings for performance
- Initialization scripts for consistent setup

### Persistence
- Data volume for persistent storage
- Configuration files mounted read-only
- Backup-friendly structure

## Integration Steps

1. **Copy files to main compose**:
   ```bash
   # Merge docker-compose.postgres.yml into main docker-compose.yml
   # Add postgres-db service under services
   # Add postgres-data volume
   # Ensure shared-net network exists
   ```

2. **Update DNS (optional)**:
   Add database hostname to `kali-dns/src/config.py`:
   ```python
   CUSTOM_RECORDS = {
       'postgres-db': '172.25.0.x',  # Database container IP
       # ... other records
   }
   ```

3. **Deploy database**:
   ```bash
   docker-compose --profile database up -d postgres-db
   ```

4. **Connect from other containers**:
   Use service name `postgres-db:5432` for connections within shared-net.

## Usage Examples

### Connect from application container
```python
import psycopg2

conn = psycopg2.connect(
    host="postgres-db",
    database="devdb",
    user="devuser",
    password="devpass123",
    port="5432"
)
```

### Command line access
```bash
docker-compose exec postgres-db psql -U devuser -d devdb
```

### Backup database
```bash
docker-compose exec postgres-db pg_dump -U devuser devdb > backup.sql
```

## Security Considerations

- Change default passwords in production
- Use environment variables for credentials
- Restrict network access to shared-net only
- Enable SSL/TLS for production connections
- Regular security updates

## Customization

### Change Database Settings
Modify `init.sql` for different schema or `postgresql.conf` for performance tuning.

### Add More Databases
Extend `init.sql` to create additional databases or users.

### Use Different Database
Replace PostgreSQL with MySQL/MariaDB, MongoDB, etc. following similar structure.

## Monitoring

The database includes health checks and can be monitored through the existing Kali-Docker monitoring stack.

## Troubleshooting

- **Connection refused**: Check if container is running and network is shared-net
- **Authentication failed**: Verify credentials in environment variables
- **Permission denied**: Ensure proper user permissions in init.sql
- **Health check failed**: Check PostgreSQL logs with `docker-compose logs postgres-db`