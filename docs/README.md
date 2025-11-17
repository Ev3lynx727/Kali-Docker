# Secure Docker Host with Firewalld

A production-ready, containerized Docker host with comprehensive security features using firewalld for network protection and access control.

## 🛡️ Security Features

- **Firewalld Integration**: Advanced firewall management following [firewalld best practices](https://dev.to/soerenmetje/how-to-secure-a-docker-host-using-firewalld-2joo)
- **Docker Security**: Hardened Docker daemon with `iptables: false`
- **Network Isolation**: Secure container networking with proper segmentation
- **Access Control**: SSH key-based authentication only
- **Monitoring**: Real-time security monitoring and alerting
- **Logging**: Centralized log aggregation with Fluent Bit
- **SELinux**: Security-enhanced Linux policies

## ⚠️ Security Considerations

**Important Security Warning**: The masquerading configuration may bypass access controls in services like Postfix. All traffic from containers appears to originate from the Docker gateway IP (typically 172.17.0.1), which may be listed as a trusted address by default in some services.

**Recommendation**: For production use with services that rely on original client IP addresses (mail servers, rate limiting, etc.), consider alternative approaches like Podman or external firewalls.

**Reference**: [Mailserver Incident Postmortem](https://www.reddit.com/r/selfhosted/comments/186bz2g/a_mailserver_incident_postmortem/)

## 🧪 Testing Firewalld Configuration

### Automated Testing

Run the comprehensive test script to verify your firewalld configuration:

```bash
./test-firewalld.sh
```

This script tests:
- Docker iptables configuration
- Firewalld service status
- Masquerading setup
- Interface configuration
- Container internet access
- Port filtering effectiveness

### Basic Connectivity Tests

```bash
# Test container internet access
docker run --rm busybox ping -c4 8.8.8.8

# Test container in custom network
docker run --rm --net secure-net busybox ping -c4 8.8.8.8

# Test port accessibility
docker run -d -p 8080:80 --name test-nginx nginx:alpine
curl http://localhost:8080  # Should work (port 80 allowed)
curl http://localhost:8081  # Should fail (port not allowed)
```

### Firewall Verification

```bash
# Check firewall status
firewall-cmd --list-all

# Verify masquerading
firewall-cmd --zone=public --query-masquerade

# Check trusted interfaces
firewall-cmd --zone=trusted --list-interfaces
```

### Security Testing

```bash
# Run comprehensive firewalld tests
./test-firewalld.sh

# Test privileged container detection
/usr/local/bin/security-check.sh

# Monitor security events
docker-compose logs -f security-monitor
```

## 🚀 Quick Start

### Prerequisites
- Docker Engine 20.10+
- Docker Compose 2.0+
- SSH key pair for authentication

### Deployment

1. **Clone and configure:**
```bash
cd Docker-host
# Add your SSH public key to enable access
echo "your-ssh-public-key-here" > ssh/authorized_keys
```

2. **Build and deploy:**
```bash
docker-compose up -d
```

3. **Verify deployment:**
```bash
docker-compose ps
docker-compose logs docker-host
```

4. **Test firewalld configuration:**
```bash
./test-firewalld.sh
```

4. **Connect securely:**
```bash
ssh -p 2222 docker@localhost
```

## 📋 Architecture

```
┌─────────────────┐    ┌──────────────────┐
│   External      │────│   Firewalld      │
│   Network       │    │   (docker zone)  │
└─────────────────┘    └──────────────────┘
                              │
                              ▼
┌─────────────────┐    ┌──────────────────┐
│ Docker Host     │────│ Security Monitor │
│ (CentOS Stream) │    └──────────────────┘
└─────────────────┘            │
                              ▼
                       ┌──────────────────┐
                       │  Log Aggregator  │
                       │   (Fluent Bit)   │
                       └──────────────────┘
```

## 🔧 Configuration

### Firewalld Zones

- **docker**: Default zone with strict rules
  - Allows: SSH (22), Docker API (2376/2377), HTTP/HTTPS
  - Denies: All other inbound traffic
  - Masquerades outbound traffic

### Docker Security

- **User namespaces**: Enabled for privilege separation
- **No new privileges**: Containers cannot gain new privileges
- **Resource limits**: Memory and CPU restrictions
- **Logging**: JSON file logging with size limits
- **Network isolation**: Internal networks for sensitive services

### SSH Security

- **Root login**: Disabled
- **Password auth**: Disabled (key-based only)
- **Port**: Changed to 2222
- **User**: docker (sudo privileges)

## 📊 Monitoring & Security

### Security Dashboard

```bash
# Access security monitor
docker-compose exec security-monitor /usr/local/bin/security-check.sh

# View real-time monitoring
docker-compose logs -f security-monitor
```

### Log Aggregation

```bash
# View aggregated logs
docker-compose exec log-aggregator tail -f /var/log/docker/aggregated.log

# Container logs
docker-compose exec log-aggregator tail -f /var/log/docker/containers.log
```

### Security Checks

The system performs automatic checks for:
- Privileged containers
- Exposed ports on 0.0.0.0
- Firewall status
- Docker daemon security
- Network configuration

## 🔒 Security Best Practices

### Container Deployment

```bash
# Run containers securely
docker run --rm \
  --read-only \
  --tmpfs /tmp \
  --memory=512m \
  --cpus=0.5 \
  --no-new-privileges \
  --security-opt=no-new-privileges \
  your-image
```

### Network Security

```bash
# Create isolated networks
docker network create --internal secure-net

# Run containers on isolated networks
docker run --network=secure-net your-app
```

### Secrets Management

```bash
# Use Docker secrets
echo "my-secret" | docker secret create my-secret -

# Use in containers
docker service create --secret my-secret your-app
```

## 🛠️ Management Commands

### Host Management

```bash
# Access Docker host
ssh -p 2222 docker@localhost

# Check firewall status
sudo firewall-cmd --list-all

# Manage Docker
sudo docker ps
sudo docker-compose up -d
```

### Security Operations

```bash
# Run security audit
/usr/local/bin/docker-monitor.sh

# Check firewall logs
sudo journalctl -u firewalld

# Monitor Docker events
sudo docker events
```

### Backup & Recovery

```bash
# Backup configuration
docker run --rm -v docker-host_data:/data -v $(pwd):/backup alpine tar czf /backup/backup.tar.gz -C /data .

# Restore configuration
docker run --rm -v docker-host_data:/data -v $(pwd):/backup alpine tar xzf /backup/backup.tar.gz -C /data
```

## 🔍 Troubleshooting

### Common Issues

**SSH Connection Failed:**
```bash
# Check SSH service
docker-compose exec docker-host systemctl status sshd

# Verify SSH keys
docker-compose exec docker-host cat /home/docker/.ssh/authorized_keys
```

**Firewall Blocking Traffic:**
```bash
# Check firewall rules
docker-compose exec docker-host firewall-cmd --list-all

# Add temporary rule
docker-compose exec docker-host firewall-cmd --add-port=8080/tcp
```

**Docker API Not Accessible:**
```bash
# Check Docker service
docker-compose exec docker-host systemctl status docker

# Verify TLS configuration
docker-compose exec docker-host ls -la /etc/docker/certs/
```

### Logs & Debugging

```bash
# View all logs
docker-compose logs

# Debug specific service
docker-compose logs docker-host

# Enter container for debugging
docker-compose exec docker-host /bin/bash
```

## 📚 Documentation

### Architecture Documentation
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Complete system architecture overview
- **[NETWORK-TOPOLOGY.md](NETWORK-TOPOLOGY.md)** - Detailed network design and flow
- **[OPERATIONS.md](OPERATIONS.md)** - Comprehensive operational procedures
- **[QUICK-REFERENCE.md](QUICK-REFERENCE.md)** - Essential commands and configurations

### Key Documentation Sections

#### 🏗️ System Architecture
- Defense-in-depth security layers
- Component relationships and dependencies
- Data flow patterns and security boundaries

#### 🌐 Network Design
- Firewalld zone configurations
- Docker network segmentation
- Traffic flow and security policies

#### 🔧 Operations
- Daily maintenance procedures
- Security monitoring and alerting
- Troubleshooting and emergency response

#### 📋 Quick Reference
- Essential commands and configurations
- Port mappings and service access
- Performance tuning and maintenance

## 📚 Advanced Configuration

### Custom Firewall Rules

```bash
# Add custom service
docker-compose exec docker-host firewall-cmd --permanent --new-service=myapp
docker-compose exec docker-host firewall-cmd --permanent --service=myapp --add-port=8080/tcp
docker-compose exec docker-host firewall-cmd --reload
```

### Docker Swarm Setup

```bash
# Initialize swarm
docker-compose exec docker-host docker swarm init

# Join worker nodes
docker-compose exec docker-host docker swarm join-token worker
```

### SELinux Policies

```bash
# Check SELinux status
docker-compose exec docker-host sestatus

# View SELinux logs
docker-compose exec docker-host sealert -a /var/log/audit/audit.log
```

## 📚 Complete Documentation Suite

### 📖 Documentation Overview
- **[README.md](README.md)** - This overview and quick start guide
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Complete system architecture and design
- **[NETWORK-TOPOLOGY.md](NETWORK-TOPOLOGY.md)** - Detailed network design and security zones
- **[OPERATIONS.md](OPERATIONS.md)** - Comprehensive operational procedures
- **[QUICK-REFERENCE.md](QUICK-REFERENCE.md)** - Essential commands and configurations
- **[ARCHITECTURE-DIAGRAM.md](ARCHITECTURE-DIAGRAM.md)** - Visual system architecture

### 🔗 Key Documentation Links

| Document | Purpose | Audience |
|----------|---------|----------|
| **README.md** | Overview & Quick Start | All users |
| **ARCHITECTURE.md** | System Design & Security | Architects, Security Teams |
| **NETWORK-TOPOLOGY.md** | Network Design & Flow | Network Engineers, DevOps |
| **OPERATIONS.md** | Daily Operations & Maintenance | System Administrators |
| **QUICK-REFERENCE.md** | Commands & Troubleshooting | Operators, Developers |
| **ARCHITECTURE-DIAGRAM.md** | Visual Architecture | All stakeholders |

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make security-focused improvements
4. Test thoroughly with `./test-firewalld.sh`
5. Update relevant documentation
6. Submit a pull request

## 📄 License

This project implements industry-standard security practices for Docker host management using firewalld and container security best practices.

## ⚠️ Security Notice

**Important Security Considerations:**

This setup provides a secure foundation but security is an ongoing process. The firewalld masquerading feature may affect services that rely on original client IP addresses (see [Reddit Postmortem](https://www.reddit.com/r/selfhosted/comments/186bz2g/a_mailserver_incident_postmortem/)).

**Regular Security Practices:**
- Update base images and system packages weekly
- Monitor logs for anomalies and security events
- Audit firewall rules and container configurations monthly
- Review access patterns and authentication logs
- Keep Docker, firewalld, and all components updated
- Run security tests regularly with `./test-firewalld.sh`

**Production Deployment:**
- Test thoroughly in staging environment first
- Implement additional monitoring and alerting
- Consider external firewalls for IP-based access control
- Use secrets management for sensitive configuration
- Implement backup and disaster recovery procedures

## 🏆 Architecture Achievements

✅ **Defense in Depth**: Multiple security layers (firewalld, Docker, container capabilities)  
✅ **Network Segmentation**: Zone-based isolation with controlled traffic flow  
✅ **Process Supervision**: systemd and Docker for reliable service management  
✅ **Comprehensive Monitoring**: Real-time security monitoring and centralized logging  
✅ **Operational Excellence**: Automated testing, health checks, and maintenance procedures  
✅ **Documentation**: Complete operational and architectural documentation suite  

This Docker-Host implementation provides enterprise-grade container security with firewalld as the network security foundation, suitable for production deployments requiring robust isolation and security controls.