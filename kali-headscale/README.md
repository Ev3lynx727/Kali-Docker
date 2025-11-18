# Kali-Headscale

A containerized Headscale setup with web UI for managing Tailscale-compatible VPN networks.

## Overview

This project provides a complete Headscale deployment with a user-friendly web interface for managing your Tailscale-compatible VPN network. Headscale is an open-source implementation of the Tailscale coordination server.

## Services

- **headscale**: The core coordination server (ports 80, 8080/udp, 9090)
- **headscale-ui**: Web interface for managing nodes, users, and ACLs (ports 8080, 8443)

## Quick Start

1. **Run the setup script**:
   ```bash
   ./setup.sh
   ```

2. **Access the web UI**:
   - Open `http://localhost:3000` in your browser
   - The UI will be served from the root path

3. **Initial Setup**:
   - Create an API key: `docker-compose exec headscale headscale apikeys create --expiration 90d`
   - Use this key to authenticate in the web UI

4. **Test the setup**:
   ```bash
   ./test.sh
   ```

## Configuration

### Headscale Configuration

The main configuration is in `config/config.yaml`. Key settings:

- **Server URL**: `http://localhost:80` (for client connections)
- **Database**: SQLite (default, no additional setup needed)
- **IP Ranges**: 100.64.0.0/10 and fd7a:115c:a1e0::/48
- **DERP**: Disabled (uses Tailscale's public servers)

### Network Configuration

- **Network**: `host-network` with subnet `172.27.0.0/16`
- **Ports**:
  - 80: Headscale HTTP API
  - 8080: Headscale WireGuard UDP
  - 9090: Headscale metrics
  - 3000: Web UI HTTP
  - 3443: Web UI HTTPS (self-signed cert)

## Usage

### Managing Nodes

1. **Create a pre-auth key**:
   ```bash
   docker-compose exec headscale headscale preauthkeys create --user <username> --reusable
   ```

2. **Register a node**:
   ```bash
   tailscale up --login-server http://localhost:80 --auth-key <preauth-key>
   ```

3. **View nodes in web UI**:
   - Go to `http://localhost:8080`
   - Navigate to the nodes section

### API Access

Headscale provides a REST API for programmatic access:

- **Base URL**: `http://localhost:80`
- **Authentication**: Use API keys created with `headscale apikeys create`

### Command Line Management

Access the headscale container for CLI operations:

```bash
docker-compose exec headscale bash
headscale nodes list
headscale users create <username>
headscale preauthkeys create --user <username>
```

## Security Considerations

- **API Keys**: Create specific keys for different purposes, not reusable for production
- **Network Isolation**: Services run in isolated Docker network
- **HTTPS**: Web UI uses self-signed certificates by default
- **Firewall**: Configure host firewall to restrict access to management ports

## Troubleshooting

### Web UI Not Loading

- Ensure both containers are running: `docker-compose ps`
- Check logs: `docker-compose logs headscale-ui`
- Verify ports aren't conflicting with other services

### Node Registration Issues

- Check server URL in client: `tailscale up --login-server http://localhost:80`
- Verify pre-auth key is valid and not expired
- Check headscale logs: `docker-compose logs headscale`

### Port Conflicts

If ports 8080/8443 conflict with other services, modify the ports in `docker-compose.yml`:

```yaml
headscale-ui:
  ports:
    - "8081:8080"  # Change host port
    - "8444:8443"
```

## Customization

### Port Configuration
If default ports conflict with other services, copy `docker-compose.override.yml.example` to `docker-compose.override.yml` and modify the ports:

```yaml
services:
  headscale:
    ports:
      - "8081:80/tcp"      # Change API port
      - "8080:8080/udp"    # Keep WireGuard
      - "9091:9090/tcp"    # Change metrics port
  headscale-ui:
    ports:
      - "8082:8080/tcp"    # Change web UI port
```

### Advanced Configuration
- **Database**: Switch to PostgreSQL for production use
- **TLS**: Configure proper certificates for HTTPS
- **ACL Policies**: Add custom access control policies
- **DERP**: Enable embedded DERP server for better connectivity

## Integration with Main Kali-Docker

This headscale setup can be integrated with the main Kali-Docker project by:

1. **Network Connection**: Connect to the main `host-network` (172.25.0.0/16)
2. **HAProxy Integration**: Configure HAProxy to proxy `/headscale*` paths to the web UI
3. **DNS Integration**: Add headscale domains to Kali-DNS for internal resolution

## File Structure

```
kali-headscale/
├── config/
│   └── config.yaml              # Headscale configuration
├── docker-compose.yml           # Service definitions
├── docker-compose.override.yml.example  # Override example
├── setup.sh                     # Quick setup script
├── test.sh                      # Test script
├── README.md                    # This documentation
├── AGENTS.md                    # Development guidelines
└── .gitignore                   # Git ignore rules
```

## Development

See `AGENTS.md` for development guidelines and coding standards.

## License

This project follows the same license as the main Kali-Docker project.