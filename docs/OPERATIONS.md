# Docker-Host Operations Guide

## Daily Operations

### System Startup

1. **Start the Docker Host**:
   ```bash
   cd Docker-host
   docker-compose up -d docker-host
   ```

2. **Verify System Health**:
   ```bash
   docker-compose ps
   docker-compose exec docker-host systemctl status firewalld docker
   ```

3. **Run Security Tests**:
   ```bash
   ./test-firewalld.sh
   ```

4. **Start Monitoring Services**:
    ```bash
    docker-compose up -d security-monitor log-aggregator
    ```

5. **Start DNS and DoH Services** (optional):
    ```bash
    docker-compose --profile dns up -d
    docker-compose --profile doh up -d
    docker-compose --profile ingress up -d
    ```

6. **Start VPN Gateway** (optional):
    ```bash
    docker-compose --profile vpn up -d
    ```

### System Monitoring

#### Real-time Monitoring
```bash
# View all service logs
docker-compose logs -f

# Monitor specific service
docker-compose logs -f docker-host

# Check container resource usage
docker stats
```

#### Security Monitoring
```bash
# Run security audit
docker-compose exec security-monitor /usr/local/bin/security-check.sh

# View firewall status
docker-compose exec docker-host firewall-cmd --list-all

# Check for privileged containers
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" | grep -v NAMES
```

#### Network Monitoring
```bash
# View network connections
docker-compose exec docker-host netstat -tuln

# Check Docker networks
docker network ls
docker network inspect host-network
```

## Container Management

### Deploying Applications

#### Method 1: Using Docker Compose (Recommended)
```yaml
# Create containers/app.yml
version: '3.8'
services:
  myapp:
    image: nginx:alpine
    networks:
      - host-network
    ports:
      - "8080:80"
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /tmp:noexec,nosuid,size=10m
```

```bash
# Deploy the application
docker-compose -f containers/app.yml up -d

# Add firewall rule for new port
docker-compose exec docker-host firewall-cmd --permanent --zone=public --add-port=8080/tcp
docker-compose exec docker-host firewall-cmd --reload
```

#### Method 2: Direct Docker Commands
```bash
# From within docker-host container
docker run -d --name myapp \
  --network host-network \
  --read-only \
  --tmpfs /tmp:noexec,nosuid,size=10m \
  --security-opt no-new-privileges:true \
  -p 8080:80 \
  nginx:alpine
```

### Managing Container Networks

#### Creating New Networks
```bash
# Create isolated network
docker-compose exec docker-host docker network create --driver bridge --internal secure-app-net

# Create network with custom subnet
docker-compose exec docker-host docker network create --driver bridge \
  --subnet 172.21.0.0/16 \
  --gateway 172.21.0.1 \
  app-network
```

#### Connecting Containers to Networks
```bash
# Connect running container to network
docker-compose exec docker-host docker network connect secure-app-net myapp

# Disconnect from network
docker-compose exec docker-host docker network disconnect host-network myapp
```

## Security Operations

### Firewall Management

#### Adding Services
```bash
# Add HTTP service
docker-compose exec docker-host firewall-cmd --permanent --zone=public --add-service=http

# Add custom port
docker-compose exec docker-host firewall-cmd --permanent --zone=public --add-port=8080/tcp

# Reload rules
docker-compose exec docker-host firewall-cmd --reload
```

#### Managing Zones
```bash
# List all zones
docker-compose exec docker-host firewall-cmd --get-zones

# View zone configuration
docker-compose exec docker-host firewall-cmd --zone=public --list-all

# Change default zone
docker-compose exec docker-host firewall-cmd --set-default-zone=public
```

#### Emergency Firewall Control
```bash
# Drop all incoming traffic (panic button)
docker-compose exec docker-host firewall-cmd --panic-on

# Restore normal operation
docker-compose exec docker-host firewall-cmd --panic-off

# Flush all rules (use with caution)
docker-compose exec docker-host firewall-cmd --complete-reload
```

### Access Control

#### SSH Key Management
```bash
# Add new SSH key
echo "ssh-rsa AAAAB3NzaC1yc... user@host" >> ssh/authorized_keys
docker-compose restart docker-host

# View authorized keys
docker-compose exec docker-host cat /home/docker/.ssh/authorized_keys
```

#### Docker API Security
```bash
# Check TLS configuration
docker-compose exec docker-host ls -la /etc/docker/certs/

# View Docker daemon configuration
docker-compose exec docker-host cat /etc/docker/daemon.json
```

## Maintenance Procedures

### System Updates

#### Updating Container Images
```bash
# Update all images
docker-compose pull

# Update specific service
docker-compose pull docker-host
docker-compose up -d docker-host

# Update monitoring services
docker-compose pull security-monitor log-aggregator
docker-compose up -d security-monitor log-aggregator
```

#### System Package Updates
```bash
# Update packages in docker-host
docker-compose exec docker-host dnf update -y

# Restart services after updates
docker-compose exec docker-host systemctl restart firewalld docker
```

### Backup and Recovery

#### Configuration Backup
```bash
# Backup firewall rules
docker-compose exec docker-host firewall-cmd --runtime-to-permanent

# Backup Docker configuration
docker run --rm -v docker-host_docker-config:/config -v $(pwd)/backup:/backup \
  alpine tar czf /backup/docker-config.tar.gz -C /config .

# Backup firewall configuration
docker run --rm -v docker-host_firewall-config:/firewall -v $(pwd)/backup:/backup \
  alpine tar czf /backup/firewall-config.tar.gz -C /firewall .
```

#### Log Management
```bash
# View recent logs
docker-compose logs --since 1h

# Export logs for analysis
docker-compose logs > system-logs-$(date +%Y%m%d).log

# Clean old logs
docker-compose exec log-aggregator find /var/log -name "*.log" -mtime +30 -delete
```

### Performance Monitoring

#### Resource Usage
```bash
# Container resource stats
docker stats

# System resource usage
docker-compose exec docker-host htop

# Network I/O
docker-compose exec docker-host ip -s link
```

#### Performance Tuning
```bash
# Adjust Docker daemon settings
docker-compose exec docker-host vi /etc/docker/daemon.json

# Modify firewall performance
docker-compose exec docker-host firewall-cmd --permanent --add-rule ipv4 filter INPUT 0 -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1460
```

## Troubleshooting

### Common Issues

#### Container Cannot Start
```bash
# Check container logs
docker-compose logs <service-name>

# Verify resource availability
docker system df

# Check Docker daemon status
docker-compose exec docker-host systemctl status docker
```

#### Network Connectivity Issues
```bash
# Test basic connectivity
docker-compose exec docker-host ping -c 3 8.8.8.8

# Check DNS resolution
docker-compose exec docker-host nslookup google.com

# Verify firewall rules
docker-compose exec docker-host firewall-cmd --list-all
```

#### Security Violations
```bash
# Check for privileged containers
docker-compose exec security-monitor /usr/local/bin/security-check.sh

# Review firewall logs
docker-compose exec docker-host journalctl -u firewalld --since "1 hour ago"

# Audit Docker events
docker-compose exec docker-host docker events --since "1h"
```

### Emergency Procedures

#### System Lockdown
```bash
# Emergency firewall lockdown
docker-compose exec docker-host firewall-cmd --panic-on

# Stop all containers
docker-compose exec docker-host docker stop $(docker ps -q)

# Disable Docker API
docker-compose exec docker-host systemctl stop docker
```

#### System Recovery
```bash
# Restore from backup
docker run --rm -v docker-host_docker-config:/config -v $(pwd)/backup:/backup \
  alpine tar xzf /backup/docker-config.tar.gz -C /config

# Restart services
docker-compose restart

# Verify system integrity
./test-firewalld.sh
```

## Scaling Operations

### Horizontal Scaling
```bash
# Add more monitoring instances
docker-compose up -d --scale security-monitor=3

# Create additional networks for segmentation
docker-compose exec docker-host docker network create --driver bridge app-net-01
docker-compose exec docker-host docker network create --driver bridge app-net-02
```

### Load Balancing
```bash
# Deploy load balancer
docker-compose exec docker-host docker run -d --name lb \
  --network host-network \
  -p 80:80 \
  nginx:alpine

# Configure backend services
docker-compose exec docker-host docker network connect app-net-01 lb
```

## Compliance and Auditing

### Security Audits
```bash
# Run comprehensive security scan
docker-compose exec security-monitor /usr/local/bin/security-check.sh

# Generate audit report
docker-compose logs --since 24h > audit-$(date +%Y%m%d).log

# Check compliance
docker-compose exec docker-host find /etc -name "*.conf" -exec grep -l "password\|secret" {} \;
```

### Log Analysis
```bash
# Search for security events
docker-compose logs | grep -i "error\|fail\|deny\|block"

# Analyze firewall activity
docker-compose exec docker-host journalctl -u firewalld | grep -E "(DENY|REJECT)"

# Monitor authentication attempts
docker-compose exec docker-host journalctl -u sshd | grep "Failed\|Accepted"
```

This operations guide provides comprehensive procedures for managing, monitoring, and maintaining the secure Docker host environment.</content>
<parameter name="filePath">C:\Users\evely\Downloads\DEV\Docker-host\OPERATIONS.md