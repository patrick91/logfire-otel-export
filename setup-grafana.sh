#!/bin/bash
set -e

# Wait for Grafana to be ready
echo "Waiting for Grafana to be ready..."
until curl -s http://localhost:3000/api/health > /dev/null 2>&1; do
    echo "Waiting for Grafana..."
    sleep 2
done
echo "Grafana is ready!"

# Configure Prometheus data source
echo "Configuring Prometheus data source..."

curl -X POST \
  http://admin:admin@localhost:3000/api/datasources \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Prometheus",
    "type": "prometheus",
    "url": "http://prometheus:9090",
    "access": "proxy",
    "isDefault": true,
    "jsonData": {
      "httpMethod": "POST"
    }
  }' 2>/dev/null || echo "Data source might already exist"

echo ""
echo "✓ Prometheus data source configured!"
echo ""
echo "You can now:"
echo "  1. Open Grafana at http://localhost:3000 (admin/admin)"
echo "  2. Import the dashboard: just import-dashboard"
echo "  3. Or go to Explore to query metrics manually"
