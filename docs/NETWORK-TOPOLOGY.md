# Docker-Host Network Topology

## High-Level Network Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Internet                                       │
└─────────────────────┬───────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        Firewalld (Public Zone)                              │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │ Ports: 22(SSH), 80(HTTP), 443(HTTPS), 2376(Docker), 2377(Swarm)       │ │
│  │ Masquerading: Enabled (NAT for container internet access)              │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────┬───────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          Docker Host Container                              │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │ systemd • firewalld • docker daemon • sshd                             │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────┬───────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        Firewalld (Trusted Zone)                             │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │ Interface: docker0 (Container-to-host communication)                   │ │
│  │ Masquerading: Disabled (Direct routing)                                │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────┬───────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Docker Networks                                   │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐             │
│  │ host-network    │  │ secure-net      │  │ isolated-net    │             │
│  │ 172.20.0.0/16  │  │ internal         │  │ internal        │             │
│  │ bridge          │  │ bridge          │  │ bridge          │             │
│  │ external access │  │ no external     │  │ no external     │             │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘             │
└─────────────────────┬───────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Container Services                                │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐             │
│  │ security-mon.   │  │ log-aggregator  │  │ user-containers │             │
│  │ monitoring      │  │ fluent-bit      │  │ applications    │             │
│  │ host-network    │  │ host-network    │  │ various nets    │             │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Detailed Network Flow

### External Traffic Flow

```
Internet Request → Firewalld Public Zone → NAT/Masquerade → Docker Host → Docker Network → Container
```

### Internal Traffic Flow

```
Container → Docker Bridge → Firewalld Trusted Zone → Docker Host → Target Container
```

### Management Traffic Flow

```
SSH/API → Firewalld Public Zone → Docker Host systemd → Docker daemon → Container Management
```

## Security Zones Detail

### Public Zone Configuration
- **Target**: `DROP` (default deny)
- **Masquerade**: `yes` (NAT outbound traffic)
- **Interfaces**: `eth0` (or detected network interface)
- **Services**:
  - `ssh` (port 22)
  - `http` (port 80)
  - `https` (port 443)
  - `docker` (ports 2376, 2377)

### Trusted Zone Configuration
- **Target**: `ACCEPT` (default allow)
- **Masquerade**: `no` (direct routing)
- **Interfaces**: `docker0` (Docker bridge)
- **Purpose**: Container-to-host communication

## Network Isolation Levels

### Level 1: Host Network (172.20.0.0/16)
```
Exposure: External
Security: Medium
Use Case: Public services, monitoring, logging
Access: Full internet access via masquerading
```

### Level 2: Secure Network (internal)
```
Exposure: None
Security: High
Use Case: Internal services, databases
Access: Container-to-container only
```

### Level 3: Isolated Network (internal)
```
Exposure: None
Security: Maximum
Use Case: Sensitive data, high-security apps
Access: Strict container isolation
```

## Firewall Rules Matrix

| Source | Destination | Protocol | Port | Action | Zone |
|--------|-------------|----------|------|--------|------|
| Internet | Docker Host | TCP | 22 | Allow | Public |
| Internet | Docker Host | TCP | 80 | Allow | Public |
| Internet | Docker Host | TCP | 443 | Allow | Public |
| Internet | Docker Host | TCP | 2376 | Allow | Public |
| Internet | Docker Host | TCP | 2377 | Allow | Public |
| Internet | HAProxy | TCP | 80 | Allow | Public |
| Internet | HAProxy | TCP | 443 | Allow | Public |
| Internet | WireGuard | UDP | 51820 | Allow | Public |
| Internet | DNS | UDP | 53 | Drop (VPN only) | Public |
| VPN Clients | DNS | UDP | 53 | Allow | Public |
| Container | Docker Host | Any | Any | Allow | Trusted |
| Container | Internet | Any | Any | Masquerade | Public |
| Container | Container | Any | Any | Allow | Bridge |

## Monitoring Points

### Network Monitoring
- **Firewalld logs**: `/var/log/firewalld`
- **Docker network stats**: `docker network inspect`
- **Container connections**: `docker exec netstat`

### Security Monitoring
- **Firewall rule hits**: `firewall-cmd --list-all`
- **Failed connections**: `journalctl -u firewalld`
- **Container network access**: Security monitor logs

## Troubleshooting Network Issues

### Container Cannot Access Internet
```bash
# Check masquerading
firewall-cmd --zone=public --query-masquerade

# Check public zone interfaces
firewall-cmd --zone=public --list-interfaces

# Verify Docker network
docker network inspect bridge
```

### Inter-Container Communication Failing
```bash
# Check trusted zone
firewall-cmd --zone=trusted --list-interfaces

# Verify Docker networks
docker network ls
docker network inspect <network-name>
```

### External Access Blocked
```bash
# Check public zone ports
firewall-cmd --zone=public --list-ports

# Verify service definitions
firewall-cmd --list-services --zone=public
```

This network topology provides defense-in-depth security while maintaining operational flexibility for containerized applications.</content>
<parameter name="filePath">C:\Users\evely\Downloads\DEV\Docker-host\NETWORK-TOPOLOGY.md