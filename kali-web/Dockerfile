FROM python:3.11-slim

# Install system tools
RUN apt update && apt install -y dnsutils && apt clean

# Install dependencies
RUN pip install --no-cache-dir dnspython flask requests

# No SSL needed, handled by HAProxy

# Copy DoH server
COPY doh_server.py /app/doh_server.py

# Expose HTTPS port
EXPOSE 443

# Run DoH server
CMD ["python", "/app/doh_server.py"]