#!/bin/bash
# Firewalld Docker Security Test Script
# Tests the configuration from the article

echo "=== Firewalld Docker Security Test ==="
echo "Testing configuration from: https://dev.to/soerenmetje/how-to-secure-a-docker-host-using-firewalld-2joo"
echo ""

# Test 1: Check if iptables is disabled for Docker
echo "1. Checking Docker iptables configuration..."
if docker info 2>/dev/null | grep -q "iptables.*false"; then
    echo "✅ Docker iptables disabled"
else
    echo "❌ Docker iptables not properly disabled"
fi
echo ""

# Test 2: Check firewalld status
echo "2. Checking firewalld status..."
if systemctl is-active --quiet firewalld; then
    echo "✅ Firewalld is running"
else
    echo "❌ Firewalld is not running"
fi
echo ""

# Test 3: Check masquerading
echo "3. Checking masquerading configuration..."
if firewall-cmd --zone=public --query-masquerade; then
    echo "✅ Masquerading enabled on public zone"
else
    echo "❌ Masquerading not enabled on public zone"
fi
echo ""

# Test 4: Check Docker interface in trusted zone
echo "4. Checking Docker interface configuration..."
if firewall-cmd --zone=trusted --list-interfaces | grep -q docker0; then
    echo "✅ Docker interface (docker0) in trusted zone"
else
    echo "❌ Docker interface not in trusted zone"
fi
echo ""

# Test 5: Test container internet access
echo "5. Testing container internet access..."
if docker run --rm busybox timeout 10 ping -c 2 8.8.8.8 >/dev/null 2>&1; then
    echo "✅ Container can access internet"
else
    echo "❌ Container cannot access internet"
fi
echo ""

# Test 6: Test custom network internet access
echo "6. Testing custom network internet access..."
docker network create test-net >/dev/null 2>&1
if docker run --rm --net test-net busybox timeout 10 ping -c 2 8.8.8.8 >/dev/null 2>&1; then
    echo "✅ Container in custom network can access internet"
else
    echo "❌ Container in custom network cannot access internet"
fi
docker network rm test-net >/dev/null 2>&1
echo ""

# Test 7: Test port filtering
echo "7. Testing port filtering..."
docker run -d -p 8080:80 --name test-nginx nginx:alpine >/dev/null 2>&1
sleep 2
if curl -s --max-time 5 http://localhost:8080 >/dev/null 2>&1; then
    echo "✅ Allowed port (80) is accessible"
else
    echo "❌ Allowed port (80) is not accessible"
fi

if curl -s --max-time 5 http://localhost:8081 >/dev/null 2>&1; then
    echo "❌ Blocked port (8081) is accessible (security issue!)"
else
    echo "✅ Blocked port (8081) is properly filtered"
fi
docker stop test-nginx >/dev/null 2>&1 && docker rm test-nginx >/dev/null 2>&1
echo ""

echo "=== Test Summary ==="
echo "If all tests show ✅, firewalld is properly configured for Docker security."
echo "Review any ❌ results and check firewalld configuration."
echo ""
echo "Security Warning: Masquerading may affect services relying on client IP addresses."
echo "See: https://www.reddit.com/r/selfhosted/comments/186bz2g/a_mailserver_incident_postmortem/"