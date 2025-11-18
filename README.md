# Kali-Docker Secure Container Host

A production-ready, containerized Docker host environment with comprehensive security features, DNS services, and VPN gateway.

## Overview

Kali-Docker provides a secure Docker host with firewalld network security, monitoring, logging, and optional DNS/DoH services with WireGuard VPN access. Built on Kali Linux for enhanced penetration testing capabilities, with S6 process supervision for reliability.

## Quick Start

1. **Start the Docker Host**:
   ```bash
   docker-compose up -d docker-host
   ```

2. **Start Security Services**:
   ```bash
   docker-compose up -d security-monitor log-aggregator
   ```

3. **Start DNS Services** (optional):
   ```bash
   docker-compose --profile dns --profile doh --profile ingress up -d
   ```

4. **Start VPN Gateway** (optional):
    ```bash
    docker-compose --profile vpn up -d
    ```

## Testing

### Test DoH API
```bash
# From within kali-web container
docker-compose exec kali-web python test_doh.py example.com

# Or external HTTPS test (requires valid cert)
curl -k -X POST -H "Content-Type: application/dns-message" \
  --data-binary @dns_query.bin https://localhost:8443/dns-query
```

### Test DNS
```bash
# Test UDP DNS
dig @localhost -p 5353 example.com

# Test VPN-restricted access
# Connect via WireGuard first, then test
dig @kali-dns -p 53 example.com
```

## Services

- **docker-host**: Kali Linux with S6 supervision, firewalld, Docker daemon
- **security-monitor**: Real-time security monitoring (Alpine Linux)
- **log-aggregator**: Fluent Bit centralized logging with memory storage
- **kali-dns**: Python DNS server with custom records (UDP 5353)
- **kali-web**: Python DoH server (HTTP 80, proxied via HAProxy)
- **wireguard**: WireGuard VPN gateway (UDP 51820)
- **haproxy**: HAProxy SSL ingress and load balancing (8443/8080)
- **n8n**: n8n workflow automation (HTTPS 5678)

## Security Features

- Firewalld zone-based network segmentation
- Docker security options and capabilities dropping
- TLS for Docker API
- VPN-restricted DNS access
- SSL/TLS for DoH

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Network Topology](docs/NETWORK-TOPOLOGY.md)
- [Operations Guide](docs/OPERATIONS.md)
- [Quick Reference](docs/QUICK-REFERENCE.md)

## Final Deployment Status

✅ **Successfully Deployed and Tested**
- All services running stably with S6 process supervision
- DNS resolution working on port 5353
- DoH API functional on port 8443 with SSL
- HAProxy ingress with automatic HTTP to HTTPS redirect
- WireGuard VPN operational
- Comprehensive logging and monitoring active
- Security features verified (firewalld, TLS, VPN restrictions)

## Requirements

- Docker and Docker Compose
- Linux host with systemd (tested on WSL2)
- At least 2GB RAM recommended
- For external access: Tailscale VPN configured

## External Access

Three methods available (see WALKTHROUGH.md):
1. Windows port forwarding to WSL2
2. Direct WSL2 Tailscale (recommended)
3. Custom HAProxy with Node.js DoH

## License

See individual service licenses.