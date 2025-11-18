# Kali-Docker Deployment Guide

This guide covers deploying the Kali-Docker secure container environment with DNS, DoH, and VPN services.

## Prerequisites

- Docker and Docker Compose installed
- Linux host with systemd
- At least 4GB RAM recommended
- Ports 22, 53, 80, 443, 2376, 2377, 51820 available

## Quick Deployment

1. **Start the core system**
   ```bash
   docker-compose up -d docker-host
   ```

2. **Wait for healthcheck to pass**
   ```bash
   docker-compose ps
   # Wait for health: healthy
   ```

3. **Start monitoring services**
   ```bash
   docker-compose up -d security-monitor log-aggregator
   ```

4. **Start DNS services**
   ```bash
   docker-compose --profile dns up -d
   ```

5. **Start DoH and ingress**
   ```bash
   docker-compose --profile doh --profile ingress up -d
   ```

6. **Start VPN (optional)**
    ```bash
    docker-compose --profile vpn up -d
    ```

7. **Start Automation (optional)**
    ```bash
    docker-compose --profile automation up -d
    ```

2. **Build and start the core system**
   ```bash
   docker-compose up -d docker-host
   ```

3. **Wait for healthcheck to pass**
   ```bash
   docker-compose ps
   # Wait for health: healthy
   ```

4. **Start DNS services**
   ```bash
   docker-compose --profile dns up -d
   ```

5. **Start DoH and ingress**
   ```bash
   docker-compose --profile doh --profile ingress up -d
   ```

6. **Start VPN (optional)**
   ```bash
   docker-compose --profile vpn up -d
   ```

## Service Overview

- **docker-host**: Main containerized Docker environment
- **kali-dns**: DNS server with custom records (UDP 53)
- **kali-web**: DoH server (HTTP 80, proxied to HTTPS 443)
- **haproxy**: SSL ingress and load balancer
- **wireguard**: VPN gateway (UDP 51820)

## Access Points

- **SSH**: localhost:2222 (user: docker, key-based auth)
- **Docker API**: localhost:2376 (TLS required)
- **DNS**: localhost:5353 (UDP)
- **DoH**: https://localhost/dns-query (POST)
- **VPN**: localhost:51820 (WireGuard)

## Configuration

### Custom DNS Records
Edit `src/config.py` in kali-dns:
```python
CUSTOM_RECORDS = {
    'myapp.local': '192.168.1.100',
    'dev.example.com': '172.25.0.10'
}
```

### WireGuard Clients
After VPN starts, get client config:
```bash
docker-compose exec wireguard cat /config/peer1/peer1.conf
```

### SSL Certificates
DoH uses self-signed certificates. For production, replace with Let's Encrypt.

## Monitoring

```bash
# View all services
docker-compose ps

# View logs
docker-compose logs -f

# Check security
docker-compose exec docker-host /usr/local/bin/docker-monitor.sh
```

## Scaling

- Add more DNS servers by scaling kali-dns
- Load balance with multiple haproxy instances
- Extend networks for additional services

## Backup

```bash
# Backup volumes
docker run --rm -v kali-docker_docker-data:/data -v $(pwd)/backup:/backup alpine tar czf /backup/docker-data.tar.gz -C /data .
```

## Deployment Success

This setup has been tested and verified working with:
- Kali Linux base image for enhanced tools
- S6-overlay for process supervision (reverted to systemd for stability)
- Fluent Bit with memory storage for efficient log aggregation
- HAProxy SSL termination for DoH
- WireGuard VPN with key-based authentication
- Firewalld zone-based security

All containers run stably without restarts.

## Security Notes

- Root password: kali (change in production)
- SSH: Key-based only, no passwords
- Firewall: Restricts DNS to VPN clients
- TLS: Required for Docker API and DoH