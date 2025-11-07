# Histogram Demo - Logfire vs Direct Prometheus Comparison

# Default recipe to display help
default:
    @just --list

# Install Python dependencies and pre-commit hooks
install:
    uv sync
    uv run pre-commit install

# Start Docker services (OTel Collector, Prometheus, Grafana)
up:
    docker compose up -d
    @echo "Services started:"
    @echo "  OTel Collector: http://localhost:4318 (OTLP), http://localhost:8889 (Prometheus metrics)"
    @echo "  Prometheus:     http://localhost:9090"
    @echo "  Grafana:        http://localhost:3000 (admin/admin)"
    @echo ""
    @echo "Prometheus will scrape from:"
    @echo "  • Logfire (via OTel):  otel-collector:8889"
    @echo "  • Direct:              localhost:8001"

# Stop Docker services
down:
    docker compose down

# Clean up everything (stop services and remove volumes)
clean:
    docker compose down -v
    @echo "All services stopped and data volumes removed"

# Complete setup: start services, configure Grafana, import both dashboards
setup: up
    @echo ""
    @echo "Waiting for services to be ready..."
    @sleep 5
    @./setup.sh
    @echo ""
    @just grafana

# Run both apps simultaneously (default)
run:
    @echo "Starting both applications..."
    @echo "  • Logfire version:  port 8000 → OTel Collector → Prometheus"
    @echo "  • Direct version:   port 8001 → Prometheus"
    @echo ""
    @echo "Press Ctrl+C to stop both"
    @echo ""
    (trap 'kill 0' SIGINT; uv run python main.py & uv run python main-prometheus.py & wait)

# Run only the Logfire version (port 8000)
run-logfire:
    uv run python main.py

# Run only the Direct Prometheus version (port 8001)
run-direct:
    uv run python main-prometheus.py

# View logs from Docker services
logs service="":
    #!/usr/bin/env bash
    if [ -z "{{service}}" ]; then
        docker compose logs -f
    else
        docker compose logs -f {{service}}
    fi

# View OTel Collector logs
otel-logs:
    docker compose logs -f otel-collector

# Restart Docker services
restart:
    docker compose restart

# Show status of Docker services
status:
    docker compose ps

# Check if services are healthy
health:
    @echo "Checking service health..."
    @echo -n "OTel Collector: "
    @curl -s http://localhost:8889/metrics > /dev/null && echo "Running" || echo "Not running"
    @echo -n "Prometheus: "
    @curl -s http://localhost:9090/-/healthy > /dev/null && echo "Running" || echo "Not running"
    @echo -n "Grafana: "
    @curl -s http://localhost:3000/api/health > /dev/null && echo "Running" || echo "Not running"

# Show Grafana dashboard links
grafana:
    @echo ""
    @echo "Grafana Dashboards:"
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    @echo ""
    @echo "  Logfire + OTel:      http://localhost:3000/d/histogram-demo-logfire"
    @echo "  Direct Prometheus:   http://localhost:3000/d/histogram-demo-direct"
    @echo ""
    @echo "  Login:               http://localhost:3000 (admin/admin)"
    @echo ""
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    @echo ""

# Open Grafana login page in browser
open-grafana:
    open http://localhost:3000

# Open Prometheus in browser
prometheus:
    open http://localhost:9090

# Open OTel Collector metrics endpoint
metrics:
    open http://localhost:8889/metrics

# View Prometheus configuration
show-config:
    @cat prometheus.yml

# View OTel Collector configuration
show-otel-config:
    @cat otel-collector-config.yml

# Run ruff linter
lint:
    uv run ruff check .

# Run ruff formatter
format:
    uv run ruff format .

# Run both linter and formatter
check: lint format
