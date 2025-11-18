# Development Guide

## Project Overview

Kali-Headscale is a containerized Headscale deployment with web UI for managing Tailscale-compatible VPN networks.

## Development Commands

### Docker Compose
- **Start services**: `docker-compose up -d`
- **Stop services**: `docker-compose down`
- **View logs**: `docker-compose logs -f`
- **Shell access**: `docker-compose exec headscale bash`
- **Rebuild**: `docker-compose up -d --build`

### Headscale CLI
- **List nodes**: `docker-compose exec headscale headscale nodes list`
- **Create user**: `docker-compose exec headscale headscale users create <username>`
- **Create API key**: `docker-compose exec headscale headscale apikeys create --expiration 90d`
- **Create pre-auth key**: `docker-compose exec headscale headscale preauthkeys create --user <username>`

## Configuration Guidelines

### Docker Compose
- Use named volumes for persistent data
- Include health checks where applicable
- Document exposed ports clearly
- Use restart policies appropriately

### Headscale Configuration
- Keep configuration in `config/config.yaml`
- Use environment-specific overrides
- Document any custom settings
- Test configuration changes thoroughly

## Testing

### Manual Testing
1. Start services: `./setup.sh`
2. Access web UI: `http://localhost:8080`
3. Create test user and pre-auth key
4. Register a test node with Tailscale client
5. Verify node appears in web UI

### Integration Testing
- Test with different Tailscale client versions
- Verify network connectivity between nodes
- Test ACL policy enforcement
- Validate API endpoints

## Deployment

### Local Development
- Use `./setup.sh` for quick setup
- Modify `docker-compose.yml` for custom configurations
- Test changes with `docker-compose up -d --build`

### Production Considerations
- Change default ports to avoid conflicts
- Configure proper TLS certificates
- Set up reverse proxy (nginx/Caddy/HAProxy)
- Implement backup strategies for data volumes
- Configure firewall rules
- Use specific image tags instead of `latest`

## Troubleshooting

### Common Issues
- **Port conflicts**: Check `docker-compose ps` and `netstat -tlnp`
- **Permission issues**: Ensure proper file permissions on config files
- **Network issues**: Verify Docker network connectivity
- **Database issues**: Check SQLite file permissions and corruption

### Debug Commands
```bash
# Check container status
docker-compose ps

# View service logs
docker-compose logs headscale
docker-compose logs headscale-ui

# Inspect networks
docker network ls
docker network inspect kali-headscale_host-network

# Access containers
docker-compose exec headscale bash
docker-compose exec headscale-ui sh
```

## Contributing

1. Test changes locally before committing
2. Update documentation for configuration changes
3. Follow the existing code structure and naming conventions
4. Add comments for complex configurations
5. Test with multiple scenarios