# Windows-WSL2 Tailscale Configuration Walkthrough

This guide walks through configuring Tailscale on Windows host with WSL2 for external access to Kali-Docker services.

## Prerequisites

- Windows 10/11 with WSL2 enabled
- Tailscale installed on Windows
- Kali-Docker running in WSL2
- HAProxy running on ports 8080/8443 in WSL2

## Step 1: Install and Configure Tailscale on Windows

1. **Download Tailscale for Windows**:
   - Visit https://tailscale.com/download
   - Download and install the Windows version

2. **Sign in to Tailscale**:
   - Launch Tailscale from Start menu
   - Sign in with your account
   - Accept the terms and join your tailnet

3. **Get Windows Tailscale IP**:
   ```powershell
   tailscale ip -4
   ```
   - Note the IP (e.g., 100.88.80.52)

## Step 2: Configure WSL2 Networking

1. **Get WSL2 IP Address**:
   ```bash
   # In WSL2 terminal
   ip route | grep default | awk '{print $3}'
   # Or
   hostname -I
   ```
   - Note the WSL2 IP (e.g., 172.25.224.1)

2. **Verify Kali-Docker Services**:
   ```bash
   cd /path/to/Kali-docker
   docker-compose --profile dns --profile doh --profile ingress ps
   ```
   - Ensure haproxy is running and ports 8080/8443 are listening

## Step 3: Configure Windows Port Forwarding

1. **Open PowerShell as Administrator**:
   - Right-click Start → Windows PowerShell (Admin)

2. **Add Port Forwarding Rules**:
   ```powershell
   # Replace <WSL2-IP> with your WSL2 IP from step 2
   $wslIp = "<WSL2-IP>"

   # Forward HTTPS (8443) for DoH
   netsh interface portproxy add v4tov4 listenport=8443 listenaddress=0.0.0.0 connectport=8443 connectaddress=$wslIp

   # Forward HTTP (8080) for redirects
   netsh interface portproxy add v4tov4 listenport=8080 listenaddress=0.0.0.0 connectport=8080 connectaddress=$wslIp
   ```

3. **Verify Port Forwarding**:
   ```powershell
   netsh interface portproxy show all
   ```
   - Should show the forwarding rules

## Step 4: Configure Windows Firewall

1. **Allow Inbound Rules**:
   - Open Windows Defender Firewall
   - Advanced settings → Inbound Rules
   - Create new rules for ports 8080 and 8443:
     - Rule Type: Port
     - TCP, Specific ports: 8080,8443
     - Allow connection
     - Apply to all profiles

2. **Test Local Access**:
   ```powershell
   # From Windows PowerShell
   curl -k https://localhost:8443/dns-query
   ```
   - Should return 405 Method Not Allowed (expected for GET)

## Step 5: Test External Access

1. **From Another Device on Tailnet**:
   ```bash
   # Replace with your Windows Tailscale IP
   curl -k https://100.88.80.52:8443/dns-query
   ```

2. **Test DoH with DNS Query**:
   ```bash
   # Create a simple DNS query (example.com A record)
   # Use a tool or script to generate binary DNS message
   # Then POST to the endpoint
   ```

3. **Verify Firewall Logs**:
   - Check Windows Firewall logs for blocked connections
   - Ensure Tailscale is connected

## Step 6: Troubleshooting

### Port Forwarding Issues
```powershell
# Check existing rules
netsh interface portproxy show all

# Delete incorrect rules
netsh interface portproxy delete v4tov4 listenport=8443 listenaddress=0.0.0.0

# Reset and re-add
```

### WSL2 IP Changes
- WSL2 IP may change on restart
- Update port forwarding rules with new IP
- Consider using WSL2 hostname resolution

### Firewall Blocking
```powershell
# Check firewall status
Get-NetFirewallProfile

# Temporarily disable for testing
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
```

### Tailscale Issues
```powershell
# Check Tailscale status
tailscale status

# Check IP
tailscale ip -4

# Restart service
Restart-Service "Tailscale"

# Check logs
tailscale bugreport
```

## Step 7: Production Considerations

1. **Persistent Configuration**:
   - Create a PowerShell script to set up port forwarding on boot
   - Use Windows Task Scheduler to run the script

2. **Security**:
   - Limit firewall rules to specific IPs if possible
   - Monitor access logs in HAProxy
   - Keep Tailscale and WSL2 updated

3. **Performance**:
   - Test latency between Windows and WSL2
   - Consider WSL2 network optimizations

## Method 2: Direct WSL2 Tailscale (Recommended)

For better isolation between Windows and WSL2, install Tailscale directly in WSL2.

### Step 1: Install Tailscale in WSL2

1. **Install Tailscale**:
   ```bash
   # In WSL2 terminal
   curl -fsSL https://tailscale.com/install.sh | sh
   ```

2. **Start Tailscale**:
   ```bash
   sudo tailscale up
   ```
   - Follow the authentication link in browser
   - WSL2 will get its own Tailscale IP

3. **Get WSL2 Tailscale IP**:
   ```bash
   tailscale ip -4
   ```
   - Note the IP (e.g., 100.64.x.x)

### Step 2: Configure Kali-Docker for Host Networking

1. **Update docker-compose.yml**:
   - Change haproxy network_mode to host
   - Remove port mappings (not needed with host networking)

2. **Restart Services**:
   ```bash
   cd /path/to/Kali-docker
   docker-compose --profile dns --profile doh --profile ingress down
   docker-compose --profile dns --profile doh --profile ingress up -d
   ```

### Step 3: Test Direct Access

1. **Test from Windows**:
   ```powershell
   # Use WSL2 Tailscale IP
   curl -k https://100.64.x.x:8443/dns-query
   ```

2. **Test from Other Devices**:
   - Access directly via WSL2 Tailscale IP
   - No Windows port forwarding needed

### Benefits of Method 2

- Complete isolation between Windows and WSL2
- Direct access to container ports
- No complex port forwarding
- Better security (separate Tailscale IPs)

### WSL2 Tailscale Troubleshooting

```bash
# Check status
tailscale status

# Check IP
tailscale ip -4

# Restart service
sudo systemctl restart tailscaled

# View logs
sudo journalctl -u tailscaled
```

## Method 3: Custom HAProxy with Node.js DoH

For Tailscale service detection and better performance, use a custom HAProxy image with Node.js DoH server.

### Step 1: Create Custom HAProxy Image

1. **Create Directory**:
   ```bash
   mkdir kali-haproxy
   cd kali-haproxy
   ```

2. **Create package.json**:
   ```json
   {
     "name": "doh-server",
     "version": "1.0.0",
     "main": "doh-server.js",
     "dependencies": {
       "dns-packet": "^5.4.0"
     }
   }
   ```

3. **Create doh-server.js**:
   ```javascript
   const dgram = require('dgram');
   const http = require('http');
   const dnsPacket = require('dns-packet');

   const DNS_HOST = 'kali-dns';
   const DNS_PORT = 53;

   const server = http.createServer((req, res) => {
     if (req.method === 'POST' && req.url === '/dns-query') {
       let body = [];
       req.on('data', chunk => body.push(chunk));
       req.on('end', () => {
         const dnsQuery = Buffer.concat(body);
         const query = dnsPacket.decode(dnsQuery);

         // Forward to DNS server
         const client = dgram.createSocket('udp4');
         const message = dnsPacket.encode(query);
         client.send(message, 0, message.length, DNS_PORT, DNS_HOST, (err) => {
           if (err) {
             res.writeHead(500);
             res.end();
             return;
           }

           client.on('message', (msg) => {
             const response = dnsPacket.decode(msg);
             const responseBuffer = dnsPacket.encode(response);
             res.writeHead(200, { 'Content-Type': 'application/dns-message' });
             res.end(responseBuffer);
             client.close();
           });
         });
       });
     } else {
       res.writeHead(405);
       res.end('Method Not Allowed');
     }
   });

   server.listen(3000, '0.0.0.0', () => {
     console.log('DoH server listening on port 3000');
   });
   ```

4. **Create Dockerfile**:
   ```dockerfile
   FROM haproxy:alpine

   # Install Node.js
   RUN apk add --no-cache nodejs npm

   # Create app directory
   WORKDIR /app

   # Copy package files
   COPY package*.json ./

   # Install dependencies
   RUN npm install

   # Copy app
   COPY doh-server.js .

   # Create HAProxy config
   RUN echo 'global
       log stdout format raw local0 info

   defaults
       log global
       mode http
       timeout connect 5000ms
       timeout client 50000ms
       timeout server 50000ms
       option httplog

   frontend http
       bind *:8080
       mode http
       redirect scheme https code 301 if !{ ssl_fc }

   frontend https
       bind *:8443 ssl crt /etc/ssl/certs/haproxy.pem
       mode http
       http-request set-header X-Forwarded-Proto https
       default_backend doh_backend

   backend doh_backend
       server doh 127.0.0.1:3000' > /usr/local/etc/haproxy/haproxy.cfg

   # Generate SSL cert
   RUN apk add --no-cache openssl && \
       openssl req -x509 -newkey rsa:4096 -keyout /etc/ssl/private/haproxy.key -out /etc/ssl/certs/haproxy.crt -days 365 -nodes -subj "/CN=localhost" && \
       cat /etc/ssl/certs/haproxy.crt /etc/ssl/private/haproxy.key > /etc/ssl/certs/haproxy.pem

   # Start both services
   CMD ["sh", "-c", "node /app/doh-server.js & haproxy -f /usr/local/etc/haproxy/haproxy.cfg"]
   ```

5. **Build Custom Image**:
   ```bash
   docker build -t kali-haproxy .
   ```

### Step 2: Update Docker Compose

1. **Modify docker-compose.yml**:
   ```yaml
   haproxy:
     image: kali-haproxy:latest  # Use custom image
     network_mode: host
     user: root
     cap_add:
       - NET_BIND_SERVICE
     depends_on:
       - kali-web
     restart: unless-stopped
     profiles:
       - ingress
   ```

2. **Remove kali-web service** (integrated into haproxy)

### Step 3: Test Node.js DoH

1. **Start Services**:
   ```bash
   docker-compose --profile dns --profile ingress up -d
   ```

2. **Test DoH**:
   ```bash
   curl -k https://localhost:8443/dns-query
   # Should work with Node.js server
   ```

### Benefits of Method 3

- Node.js enables Tailscale service auto-detection
- Better HTTP performance than Python
- Integrated DoH and proxy in single container
- Smaller footprint (no separate kali-web)

### Node.js Troubleshooting

```bash
# Check Node.js logs
docker logs kali-haproxy | grep -v haproxy

# Test Node.js directly
docker exec kali-haproxy node /app/doh-server.js
```

## Alternative Approaches

1. **Windows Docker Desktop**:
   - Use Docker Desktop for Windows
   - Run Kali-Docker natively on Windows

2. **Reverse Proxy on Windows**:
   - Install nginx/haproxy on Windows
   - Proxy to WSL2 services

## Support

- Tailscale documentation: https://tailscale.com/kb
- WSL2 networking: https://docs.microsoft.com/en-us/windows/wsl/networking
- Kali-Docker troubleshooting: See TROUBLESHOOTING.md