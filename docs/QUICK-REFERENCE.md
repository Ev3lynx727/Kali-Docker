# Docker-Host Quick Reference

## 🚀 Quick Start

```bash
# Deploy complete system
cd Docker-host
docker-compose up -d

# Test everything works
./test-firewalld.sh
```

## 📊 Status Checks

```bash
# System health
docker-compose ps
docker-compose exec docker-host systemctl status firewalld docker

# Security status
docker-compose exec security-monitor /usr/local/bin/security-check.sh

# Firewall status
docker-compose exec docker-host firewall-cmd --list-all

# Network status
docker network ls
```

## 🔧 Common Operations

### Container Management
```bash
# Deploy application
docker-compose -f containers/secure-webapp.yml up -d

# View logs
docker-compose logs -f

# Access container shell
docker-compose exec docker-host /bin/bash
```

### Firewall Management
```bash
# Add port
firewall-cmd --permanent --zone=public --add-port=8080/tcp
firewall-cmd --reload

# Add service
firewall-cmd --permanent --zone=public --add-service=http
firewall-cmd --reload

# Check status
firewall-cmd --list-all
```

### Network Management
```bash
# Create network
docker network create --driver bridge --internal secure-net

# Connect container
docker network connect secure-net mycontainer

# Inspect network
docker network inspect secure-net
```

## 🛡️ Security Operations

### Access Control
```bash
# SSH access (port 2222)
ssh -p 2222 docker@localhost

# Docker API (TLS on 2376)
docker -H tcp://localhost:2376 --tlsverify ps
```

### Monitoring
```bash
# Real-time logs
docker-compose logs -f log-aggregator

# Security audit
/usr/local/bin/security-check.sh

# Resource usage
docker stats
```

## 🔍 Troubleshooting

### Quick Diagnostics
```bash
# Test connectivity
docker run --rm busybox ping -c 3 8.8.8.8

# Check services
systemctl status firewalld docker sshd

# View errors
journalctl -u firewalld --since "1 hour ago"
```

### Emergency Commands
```bash
# Lock down firewall
firewall-cmd --panic-on

# Restart services
systemctl restart firewalld docker

# Full system restart
docker-compose restart
```

## 📋 Configuration Files

| File | Purpose | Location |
|------|---------|----------|
| `docker-compose.yml` | Service orchestration | `./` |
| `Dockerfile` | Host container build | `./` |
| `docker-init.sh` | Initialization script | `./` |
| `test-firewalld.sh` | Security testing | `./` |
| `fluent-bit.conf` | Log aggregation | `./` |
| `containers/*.yml` | Application templates | `./containers/` |
| `ssh/authorized_keys` | SSH access keys | `./ssh/` |

## 🔐 Security Zones

| Zone | Purpose | Interfaces | Masquerade |
|------|---------|------------|------------|
| **public** | External traffic | `eth0` | Yes |
| **trusted** | Container traffic | `docker0` | No |

## 🌐 Networks

| Network | Subnet | Access | Purpose |
|---------|--------|--------|---------|
| **host-network** | 172.20.0.0/16 | External | Main services |
| **secure-net** | internal | None | Isolated apps |
| **isolated-net** | internal | None | High security |

## 📊 Ports

| Port | Service | Access | Security |
|------|---------|--------|----------|
| 22 | SSH | Key-only | High |
| 80 | HTTP | Public | Medium |
| 443 | HTTPS | Public | High |
| 2376 | Docker API | TLS | High |
| 2377 | Docker Swarm | Restricted | High |
| 2222 | SSH (host) | Key-only | High |

## ⚡ Performance Tuning

```bash
# Docker performance
echo '{"log-driver": "json-file", "log-opts": {"max-size": "10m"}}' > /etc/docker/daemon.json

# Firewall optimization
firewall-cmd --permanent --add-rule ipv4 filter INPUT 0 -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1460

# Network optimization
docker network create --driver bridge --opt com.docker.network.bridge.name=mybridge mynet
```

## 📝 Log Locations

| Component | Log Location | Access Command |
|-----------|--------------|----------------|
| Firewalld | `/var/log/firewalld` | `journalctl -u firewalld` |
| Docker | `/var/log/docker` | `docker-compose logs` |
| SSH | `/var/log/secure` | `journalctl -u sshd` |
| System | `/var/log/messages` | `journalctl` |
| Containers | `/var/lib/docker/containers` | `docker logs <container>` |

## 🔄 Maintenance Schedule

- **Daily**: Check security status with `./test-firewalld.sh`
- **Weekly**: Update container images with `docker-compose pull`
- **Monthly**: Review firewall rules and access logs
- **Quarterly**: Full security audit and system updates

## 📞 Emergency Contacts

- **System Down**: `docker-compose restart`
- **Security Breach**: `firewall-cmd --panic-on`
- **Data Loss**: Restore from backups in `./backup/`
- **Performance Issues**: Check `docker stats` and `htop`

---

**Remember**: Always test security changes in a development environment before applying to production systems.</content>
<parameter name="filePath">C:\Users\evely\Downloads\DEV\Docker-host\QUICK-REFERENCE.md