# Kali-Docker Troubleshooting Guide

Common issues and solutions for the Kali-Docker setup.

## Build Issues

### dnf/apt package errors
**Error**: `dnf: command not found` or package installation fails
**Solution**: Ensure using correct base image (Kali uses apt, CentOS uses dnf). Check Dockerfile for package manager consistency.

### S6-overlay /init not found
**Error**: `exec: "/init": stat /init: no such file or directory`
**Solution**: S6-overlay not installed correctly. Revert to systemd by removing S6 lines and using `CMD ["/usr/local/bin/docker-init.sh"]`.

### systemctl enable fails
**Error**: `Failed to enable unit: Unit sshd.service does not exist`
**Solution**: Use correct service name (`ssh` for Debian/Kali instead of `sshd`).

### useradd group exists
**Error**: `useradd: group docker exists - if you want to add this user to that group, use -g.`
**Solution**: Use `-g docker` instead of `-G docker` for primary group.

### pip install conflicts
**Error**: `--break-system-packages` issues
**Solution**: Use system packages instead: `apt install docker-compose-plugin`.

## Runtime Issues

### Network overlap
**Error**: `Pool overlaps with other one on this address space`
**Solution**: Change subnet in docker-compose.yml networks (e.g., 172.25.0.0/16).

### Port already allocated
**Error**: `Bind for 0.0.0.0:80 failed: port is already allocated`
**Solution**: Remove conflicting port mappings. Ensure only one service binds to external ports.

### HAProxy config errors
**Error**: `Missing LF on last line`
**Solution**: Add newline at end of haproxy.cfg file.

### Fluent Bit config errors
**Error**: `Sections 'multiline_parser' and 'parser' are not valid in the main configuration file`
**Solution**: Move parser sections to separate parsers.conf file, reference with Parsers_File directive.

### Container restarting
**Error**: Security monitor or log aggregator restarting
**Solution**: For security monitor, change CMD to loop script. For log aggregator, fix config and remove file outputs if volume is read-only.

### Container healthcheck fails
**Error**: Healthcheck timeout
**Solution**: Check systemctl status in container: `docker-compose exec docker-host systemctl status firewalld`.

### DNS resolution fails
**Error**: nslookup times out
**Solution**:
- Check kali-dns is running: `docker-compose ps`
- Verify port 53 not blocked by firewall
- Test internal: `docker-compose exec kali-dns dig @localhost -p 5353 example.com`

### DoH requests fail
**Error**: HTTPS connection refused
**Solution**:
- Check haproxy and kali-web are running
- Verify SSL certificate: `openssl s_client -connect localhost:443`
- Test backend: `curl http://kali-web:80/dns-query`

### WireGuard connection fails
**Error**: Handshake timeout
**Solution**:
- Check client config: `docker-compose exec wireguard cat /config/peer1/peer1.conf`
- Verify UDP 51820 not blocked
- Check server logs: `docker-compose logs wireguard`

## Service-Specific Issues

### Docker daemon not starting
```bash
# Check status
docker-compose exec docker-host systemctl status docker

# Restart
docker-compose exec docker-host systemctl restart docker
```

### Firewall blocking traffic
```bash
# Check rules
docker-compose exec docker-host firewall-cmd --list-all

# Reload rules
docker-compose exec docker-host firewall-cmd --reload
```

### SSH access denied
```bash
# Check SSH service
docker-compose exec docker-host systemctl status ssh

# Verify authorized_keys
docker-compose exec docker-host cat /home/docker/.ssh/authorized_keys
```

## Logs and Debugging

### View all logs
```bash
docker-compose logs -f
```

### Service-specific logs
```bash
docker-compose logs -f kali-dns
docker-compose logs -f haproxy
```

### Container shell access
```bash
docker-compose exec docker-host bash
docker-compose exec kali-dns sh
```

### Network inspection
```bash
# Docker networks
docker network ls
docker network inspect kali-docker_host-network

# Container interfaces
docker-compose exec docker-host ip addr
```

## Performance Issues

### High CPU usage
- Check for privileged containers
- Monitor with `docker stats`
- Limit container resources in compose

### Memory issues
- Increase host RAM
- Add memory limits: `mem_limit: 512m`

### Network latency
- Use host networking for low-latency services
- Check MTU settings

## Recovery Procedures

### Restart all services
```bash
docker-compose down
docker-compose up -d
```

### Clean rebuild
```bash
docker-compose down -v
docker system prune -f
docker-compose up -d --build
```

### Emergency access
- Use `docker exec -it secure-docker-host bash` for direct access
- Disable firewall temporarily: `firewall-cmd --panic-off`

## Verified Fixes

The following issues have been resolved in the current setup:
- Network overlaps: Changed subnet to 172.25.0.0/16
- HAProxy config: Added newline to haproxy.cfg
- Fluent Bit config: Separated parsers, added memory storage
- Container restarts: Implemented looping for security monitor, fixed log aggregator
- Build errors: Fixed apt vs dnf, useradd groups, systemctl services
- Port conflicts: Removed overlapping port mappings

All services now run stably.

## Getting Help

- Check Docker logs: `docker-compose logs`
- Verify configurations match DEPLOY.md
- Test individual services before full deployment
- Use `docker-compose config` to validate compose file