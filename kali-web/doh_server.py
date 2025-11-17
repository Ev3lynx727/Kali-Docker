#!/usr/bin/env python3
"""
Simple DNS over HTTPS (DoH) server using Flask
Proxies HTTPS DNS queries to UDP DNS server
"""

import dns.message
import dns.query
import ssl
from flask import Flask, request, Response
import socket

app = Flask(__name__)

DNS_HOST = 'kali-dns'  # Docker service name
DNS_PORT = 53

@app.route('/dns-query', methods=['POST'])
def dns_query():
    try:
        # Get DNS message from POST body
        dns_data = request.get_data()
        query = dns.message.from_wire(dns_data)

        # Send to UDP DNS server
        response = dns.query.udp(query, DNS_HOST, port=DNS_PORT, timeout=5)

        # Return response
        return Response(response.to_wire(), mimetype='application/dns-message')
    except Exception as e:
        app.logger.error(f"DoH error: {e}")
        return Response(b'', status=500)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80, threaded=True)