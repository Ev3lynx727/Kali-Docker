# Docker-Host Architecture Documentation

## Overview

The Docker-Host is a production-ready, containerized Docker host environment with comprehensive security features implemented using firewalld. This architecture provides a secure, isolated, and manageable container runtime environment suitable for development, testing, and production deployments.

## Core Architecture Principles

### 1. **Containerized Host**
- The Docker host itself runs as a privileged container
- Full Linux system with systemd, firewalld, and Docker daemon
- Provides complete isolation from the underlying host system

### 2. **Network-Centric Security**
- Firewalld as the central network policy enforcement point
- Zone-based network segmentation
- Masquerading for controlled internet access

### 3. **Defense in Depth**
- Multiple security layers (firewalld, Docker, container capabilities)
- Principle of least privilege
- Comprehensive monitoring and logging

## System Components

### 🏗️ Core Infrastructure

#### Docker-Host Container
**Purpose**: Primary containerized host system
**Technology**: CentOS Stream 9 with systemd
**Key Services**:
- `systemd` - System and service manager
- `firewalld` - Network firewall and NAT
- `docker` - Container runtime
- `sshd` - Secure shell access

**Capabilities**:
- `NET_ADMIN` - Network interface management
- `NET_RAW` - Raw socket access for networking
- `SYS_ADMIN` - System administration tasks

**Volumes**:
- `/var/run/docker.sock` - Docker daemon socket
- `/var/lib/docker` - Docker data persistence
- `/etc/docker` - Docker configuration
- `/etc/firewalld` - Firewall configuration
- `/home/docker/.ssh` - SSH keys

### 🛡️ Security Components

#### Security Monitor Container
**Purpose**: Real-time security monitoring and alerting
**Technology**: Alpine Linux with monitoring tools
**Functions**:
- Automated security scans
- Privileged container detection
- Firewall status monitoring
- Network policy validation

#### Log Aggregator Container
**Purpose**: Centralized logging and analysis
**Technology**: Fluent Bit on Alpine Linux
**Functions**:
- Docker container log aggregation
- Systemd service log collection
- Firewall event logging
- Structured log processing

### DNS Server Container (kali-dns)
**Purpose**: Internal DNS resolution with custom records
**Technology**: Python with dnspython
**Functions**:
- UDP DNS on port 53
- Custom domain resolution
- Forwarding to Cloudflare (1.1.1.1)
- S6 process supervision

### DoH Server Container (kali-web)
**Purpose**: DNS over HTTPS for encrypted DNS queries
**Technology**: Python Flask with dnspython
**Functions**:
- HTTPS DNS queries on port 443 (via HAProxy)
- Proxy to internal DNS server
- Self-signed SSL certificates

### WireGuard VPN Container
**Purpose**: Secure VPN gateway for external access
**Technology**: Linuxserver WireGuard
**Functions**:
- VPN tunnel on port 51820/UDP
- Client configuration for secure access
- Internal subnet 10.0.0.0/24

### HAProxy Ingress Container
**Purpose**: High-performance load balancing and SSL termination
**Technology**: HAProxy Alpine
**Functions**:
- SSL termination on port 443
- HTTP to HTTPS redirect
- Routing to DoH backend
- Enterprise-grade reliability

### 🌐 Network Architecture

#### Network Zones (Firewalld)

```
┌─────────────────────────────────────────────────────────────┐
│                    PUBLIC ZONE                              │
│  • Default zone for external traffic                       │
│  • Masquerading enabled for internet access                │
│  • Restricted inbound ports (22,80,443,2376,2377)          │
│  • Network interface connected                              │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                    TRUSTED ZONE                             │
│  • docker0 interface for container communication           │
│  • Internal container-to-host traffic                      │
│  • No masquerading (direct communication)                  │
└─────────────────────────────────────────────────────────────┘
```

#### Docker Networks

**host-network (172.20.0.0/16)**:
- Bridge network connecting all services
- External access enabled
- Used for inter-service communication

**secure-net (internal)**:
- Isolated bridge network
- No external access
- For sensitive internal services

**isolated-net (internal)**:
- Maximum isolation network
- No external or cross-network access
- For high-security workloads

## Data Flow Architecture

### Network Traffic Flow

```
Internet Traffic
        │
        ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Firewalld     │────▶│   Docker Host   │────▶│   Containers    │
│   (Public Zone) │     │   (Gateway)     │     │   (Services)    │
└─────────────────┘     └─────────────────┘     └─────────────────┘
        ▲                       ▲                       │
        │                       │                       ▼
        └───────────────────────┼─────────────────▶ External APIs
                                │
                                ▼
                       ┌─────────────────┐
                       │   Firewalld     │
                       │ (Trusted Zone)  │
                       └─────────────────┘
```

### Container Communication Patterns

1. **External Access**:
   - Container → docker0 → firewalld (trusted) → firewalld (public) → Internet
   - NAT/masquerading applied for outbound traffic

2. **Inter-Container Communication**:
   - Container → Docker network bridge → Target container
   - Bypasses firewalld for performance

3. **Host-to-Container Communication**:
   - Host → docker0 → Container
   - Controlled by trusted zone policies

## Security Architecture

### Defense Layers

#### 1. **Network Layer (Firewalld)**
- **Zone-based filtering**: Public, trusted, and custom zones
- **Service-based rules**: Predefined service templates
- **Port-based access**: Explicit port allowances
- **Interface isolation**: Different policies per network interface

#### 2. **Container Layer (Docker)**
- **Capability dropping**: Minimal Linux capabilities
- **User namespace**: Non-root container execution
- **Security options**: no-new-privileges, seccomp profiles
- **Resource limits**: CPU, memory, and I/O restrictions

#### 3. **System Layer (Host)**
- **SSH hardening**: Key-based authentication only
- **Service isolation**: systemd service management
- **Audit logging**: Comprehensive system activity logging

### Security Policies

#### Access Control
```yaml
# SSH Access
- Protocol: SSH v2 only
- Authentication: Public key only
- Users: docker (sudo enabled)
- Ports: 2222 (non-standard)

# Docker API
- TLS: Required for remote access
- Authentication: Certificate-based
- Ports: 2376 (TLS), 2377 (Swarm)

# Web Services
- Ports: 80 (HTTP), 443 (HTTPS)
- SSL/TLS: Enforced on 443
- Rate limiting: Via firewalld
```

#### Network Segmentation
```yaml
networks:
  public:
    exposure: external
    security: medium
    services: ["http", "https", "ssh"]

  trusted:
    exposure: internal
    security: high
    services: ["docker", "monitoring"]

  isolated:
    exposure: none
    security: maximum
    services: ["sensitive-apps"]
```

## Deployment Architecture

### Container Lifecycle

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Docker Host   │────▶│  Firewalld      │────▶│   Networks      │
│   (Boot)        │     │  (Configure)    │     │   (Create)      │
└─────────────────┘     └─────────────────┘     └─────────────────┘
        │                       │                       │
        ▼                       ▼                       ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│ Security Setup  │────▶│ Service Start   │────▶│   Monitoring    │
│ (Initialize)    │     │  (systemd)      │     │   (Begin)       │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

### Service Dependencies

```
docker-host
├── firewalld (network security)
├── docker (container runtime)
├── sshd (remote access)
└── systemd (service management)

security-monitor
├── docker-host (API access)
└── docker.sock (monitoring)

log-aggregator
├── docker-host (log sources)
└── fluent-bit (processing)
```

## Monitoring and Observability

### Metrics Collection

#### System Metrics
- **Firewalld**: Rule hits, dropped packets, active connections
- **Docker**: Container status, resource usage, network I/O
- **System**: CPU, memory, disk, network interface statistics

#### Security Metrics
- **Authentication attempts**: SSH login success/failure
- **Network anomalies**: Unusual traffic patterns
- **Container events**: Privilege escalation attempts
- **Firewall violations**: Blocked connection attempts

### Logging Architecture

```
Container Logs ──┐
System Logs ────▶ Fluent Bit ──▶ Elasticsearch/Kibana
Firewall Logs ──┘
Application Logs ┘
```

### Alerting Rules

#### Critical Alerts
- Firewall service failure
- Docker daemon crash
- Privileged container creation
- Unauthorized network access

#### Warning Alerts
- High resource usage
- Failed authentication attempts
- Network connectivity issues
- Log aggregation failures

## Operational Procedures

### Startup Sequence

1. **Container Initialization**
   ```bash
   docker-compose up -d docker-host
   ```

2. **Network Configuration**
   ```bash
   # Automatic firewalld setup
   # Docker network creation
   # Service dependency resolution
   ```

3. **Security Validation**
   ```bash
   ./test-firewalld.sh
   ```

4. **Monitoring Activation**
   ```bash
   docker-compose up -d security-monitor log-aggregator
   ```

### Maintenance Operations

#### Security Updates
```bash
# Update container images
docker-compose pull
docker-compose up -d

# Update firewalld rules
docker-compose exec docker-host firewall-cmd --reload
```

#### Network Changes
```bash
# Add new network
docker-compose exec docker-host docker network create new-net

# Update firewall rules
docker-compose exec docker-host firewall-cmd --permanent --zone=public --add-port=8080/tcp
```

#### Log Management
```bash
# View aggregated logs
docker-compose logs log-aggregator

# Rotate logs
docker-compose exec log-aggregator fluent-bit -c /fluent-bit/etc/fluent-bit.conf --dry-run
```

## Performance Considerations

### Network Performance
- **Bridge networks**: Low-latency inter-container communication
- **Direct routing**: Minimal hops for internal traffic
- **Masquerading overhead**: NAT impact on external traffic

### Security Performance
- **Firewall processing**: Minimal impact on internal traffic
- **Container isolation**: Namespace overhead
- **Monitoring overhead**: Log processing resource usage

### Scalability Limits
- **Container density**: Limited by host resources
- **Network complexity**: Firewalld rule management
- **Log volume**: Storage and processing capacity

## Troubleshooting Guide

### Common Issues

#### Network Connectivity
**Symptom**: Containers cannot access internet
**Solution**:
```bash
# Check masquerading
firewall-cmd --zone=public --query-masquerade

# Verify interface configuration
firewall-cmd --list-all
```

#### Firewall Blocking
**Symptom**: Legitimate traffic blocked
**Solution**:
```bash
# Check zone assignments
firewall-cmd --get-active-zones

# Add missing rules
firewall-cmd --permanent --zone=public --add-service=http
```

#### Container Access
**Symptom**: Cannot connect to container services
**Solution**:
```bash
# Verify port mappings
docker-compose ps

# Check firewalld rules
firewall-cmd --list-ports
```

### Diagnostic Commands

```bash
# System status
docker-compose exec docker-host systemctl status firewalld docker

# Network diagnostics
docker-compose exec docker-host ip route
docker-compose exec docker-host docker network ls

# Security audit
docker-compose exec security-monitor /usr/local/bin/security-check.sh

# Log inspection
docker-compose logs --tail=100 log-aggregator
```

## Future Enhancements

### Planned Improvements

#### Advanced Security
- **Intrusion Detection**: Integration with fail2ban or OSSEC
- **Container Scanning**: Automated vulnerability assessment
- **Zero Trust Networking**: Service mesh integration

#### Performance Optimization
- **Network Acceleration**: eBPF-based packet processing
- **Resource Management**: Advanced container scheduling
- **Storage Optimization**: Layer caching and deduplication

#### Observability Enhancement
- **Distributed Tracing**: End-to-end request tracking
- **Metrics Aggregation**: Prometheus federation
- **AI-powered Monitoring**: Anomaly detection

### Extension Points

#### Custom Security Modules
```yaml
# Plugin architecture for additional security tools
security_modules:
  - name: "ids"
    image: "suricata:latest"
    networks: ["monitoring"]
  - name: "waf"
    image: "modsecurity:latest"
    networks: ["public"]
```

#### Network Extensions
```yaml
# Advanced networking capabilities
network_features:
  - service_mesh: "istio"
  - load_balancer: "traefik"
  - vpn_gateway: "wireguard"
```

This architecture provides a robust, secure, and scalable foundation for containerized applications with enterprise-grade security and operational capabilities.</content>
<parameter name="filePath">C:\Users\evely\Downloads\DEV\Docker-host\ARCHITECTURE.md