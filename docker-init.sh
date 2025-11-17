#!/bin/bash
# Docker Host Initialization Script
# Sets up secure Docker environment with firewalld

echo "=== Docker Host Security Initialization ==="

# Start systemd (required for firewalld and docker)
exec /usr/sbin/init

# Note: Services are managed by S6-overlay
# Initialization setup runs here

# Configure firewalld for Docker (following firewalld best practices)
echo "Configuring firewalld for Docker..."

# Set default zone to public (more restrictive than docker zone)
firewall-cmd --set-default-zone=public

# Add masquerading to public zone for container internet access
firewall-cmd --permanent --zone=public --add-masquerade

# Add Docker interface to trusted zone for container-to-host communication
firewall-cmd --permanent --zone=trusted --add-interface=docker0

# Add network interface to public zone (replace eth0 with actual interface)
# This allows containers in custom networks to access internet
NETWORK_IFACE=$(ip route | grep default | awk '{print $5}' | head -1)
if [ -n "$NETWORK_IFACE" ]; then
    firewall-cmd --permanent --zone=public --add-interface=$NETWORK_IFACE
fi

# Reload firewall rules
firewall-cmd --reload

# Start services
echo "Starting firewalld..."
systemctl start firewalld

# Run security setup
echo "Running security setup..."
/usr/local/bin/docker-security-setup.sh

# Start Docker daemon
echo "Starting Docker daemon..."
systemctl start docker

# Start SSH
echo "Starting SSH..."
systemctl start ssh

# Generate Docker TLS certificates if not exist
echo "Generating Docker TLS certificates..."
if [ ! -f /etc/docker/certs/ca.pem ]; then
    mkdir -p /etc/docker/certs
    # Generate CA
    openssl genrsa -out /etc/docker/certs/ca-key.pem 4096
    openssl req -new -x509 -days 365 -key /etc/docker/certs/ca-key.pem -sha256 -out /etc/docker/certs/ca.pem -subj "/C=US/ST=State/L=City/O=Org/CN=ca"
    # Generate server key
    openssl genrsa -out /etc/docker/certs/server-key.pem 4096
    # Generate server cert
    openssl req -subj "/CN=docker-host" -new -key /etc/docker/certs/server-key.pem -out /etc/docker/certs/server.csr
    echo "subjectAltName = DNS:docker-host,IP:127.0.0.1,IP:172.20.0.1" > /etc/docker/certs/extfile.cnf
    openssl x509 -req -days 365 -in /etc/docker/certs/server.csr -CA /etc/docker/certs/ca.pem -CAkey /etc/docker/certs/ca-key.pem -CAcreateserial -out /etc/docker/certs/server-cert.pem -extfile /etc/docker/certs/extfile.cnf
    # Set permissions
    chmod 600 /etc/docker/certs/server-key.pem
    chmod 644 /etc/docker/certs/ca.pem /etc/docker/certs/server-cert.pem
    echo "TLS certificates generated."
else
    echo "TLS certificates already exist."
fi

# Create secure Docker networks
echo "Creating secure Docker networks..."
docker network create --driver bridge --internal --label secure=true secure-net 2>/dev/null || true
docker network create --driver bridge --internal --label secure=true isolated-net 2>/dev/null || true

# Configure firewall for VPN-restricted DNS access
echo "Configuring firewall for VPN DNS access..."
# Allow DNS (UDP 53) only from WireGuard VPN subnet (10.0.0.0/24)
firewall-cmd --permanent --zone=public --add-rich-rule='rule family="ipv4" source address="10.0.0.0/24" port port="53" protocol="udp" accept'
# Drop DNS from other sources
firewall-cmd --permanent --zone=public --add-rich-rule='rule family="ipv4" port port="53" protocol="udp" drop'

# Display security status
echo ""
echo "=== Security Status ==="
/usr/local/bin/docker-monitor.sh

echo ""
echo "=== Docker Host Ready ==="
echo "SSH access: docker@<host> (key-based only)"
echo "Docker API: localhost:2376 (TLS required)"
echo "Web access: Ports 80/443 open"
echo ""
echo "Use 'docker-monitor.sh' to check security status"
echo "Use 'docker-security-setup.sh' to reconfigure security"

# Keep container running
exec tail -f /dev/null