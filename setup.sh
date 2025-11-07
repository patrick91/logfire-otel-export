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

# Import both dashboards
echo "Importing Logfire dashboard..."
curl -X POST \
  http://admin:admin@localhost:3000/api/dashboards/db \
  -H 'Content-Type: application/json' \
  -d @grafana-dashboard.json 2>/dev/null

echo "✓ Logfire dashboard imported!"
echo ""

echo "Importing Direct Prometheus dashboard..."
curl -X POST \
  http://admin:admin@localhost:3000/api/dashboards/db \
  -H 'Content-Type: application/json' \
  -d @grafana-dashboard-direct.json 2>/dev/null

echo "✓ Direct dashboard imported!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ Setup complete! Both dashboards are ready."
echo ""
echo "Next steps:"
echo "  1. Run both apps:        just run"
echo "  2. View dashboards:      just grafana"
echo ""
echo "Compare both dashboards side-by-side!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
