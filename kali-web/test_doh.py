#!/usr/bin/env python3
"""
Test script for DoH (DNS over HTTPS) functionality
Tests the kali-web DoH server
"""

import dns.message
import dns.query
import requests
import sys

def test_doh(domain="example.com", doh_url="http://kali-web/dns-query"):
    """Test DoH by querying a domain and printing response."""
    try:
        # Create DNS query
        query = dns.message.make_query(domain, dns.rdatatype.A)
        query_data = query.to_wire()

        # Send POST request to DoH server
        headers = {'Content-Type': 'application/dns-message'}
        response = requests.post(doh_url, data=query_data, headers=headers, timeout=5)

        if response.status_code == 200:
            # Parse DNS response
            response_msg = dns.message.from_wire(response.content)
            print(f"DoH test successful for {domain}")
            print(f"Response: {response_msg}")
            return True
        else:
            print(f"DoH test failed: HTTP {response.status_code}")
            return False
    except Exception as e:
        print(f"DoH test error: {e}")
        return False

if __name__ == "__main__":
    domain = sys.argv[1] if len(sys.argv) > 1 else "example.com"
    success = test_doh(domain)
    sys.exit(0 if success else 1)