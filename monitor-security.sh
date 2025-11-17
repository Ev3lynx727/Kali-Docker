#!/bin/sh
# Docker Security Monitor Script

echo "=== Docker Security Monitor ==="
echo "Monitoring started at: $(date)"
echo ""

while true; do
    echo "$(date): Running security checks..."

    # Run security audit
    /usr/local/bin/security-check.sh

    # Check for suspicious activity
    echo ""
    echo "=== Suspicious Activity Check ==="

    # Check for privileged containers
    privileged_count=$(docker ps --format '{{.Names}}' | xargs -I {} docker inspect {} | jq -r '.HostConfig.Privileged' | grep -c true)
    if [ "$privileged_count" -gt 0 ]; then
        echo "⚠️  ALERT: $privileged_count privileged containers detected!"
    fi

    # Check for exposed ports
    exposed_ports=$(docker ps --format '{{.Names}} {{.Ports}}' | grep -c "0.0.0.0:")
    if [ "$exposed_ports" -gt 0 ]; then
        echo "⚠️  ALERT: $exposed_ports containers exposing ports to 0.0.0.0!"
    fi

    # Check firewall status
    if command -v firewall-cmd >/dev/null 2>&1; then
        firewall_state=$(firewall-cmd --state 2>/dev/null)
        if [ "$firewall_state" != "running" ]; then
            echo "⚠️  ALERT: Firewall is not running!"
        fi
    fi

    echo ""
    echo "Next check in 5 minutes..."
    sleep 300
done