# Logfire Histogram Demo with OpenTelemetry & Grafana

A practical demonstration of histogram metrics using **Pydantic Logfire** with **OpenTelemetry** and **Grafana** visualization, following the [Grafana guide on visualizing Prometheus histograms](https://grafana.com/blog/2020/06/23/how-to-visualize-prometheus-histograms-in-grafana/).

## What This Demo Shows

This project demonstrates:
- How to create and instrument histograms in Python using **Logfire** (Pydantic's observability platform)
- Exporting metrics via **OpenTelemetry** protocol to a collector
- Using **OpenTelemetry Collector** to transform and export metrics to Prometheus
- Visualizing histogram data in **Grafana** using different panel types
- Understanding OpenTelemetry histograms, cumulative buckets, and quantiles

## Architecture

This demo runs **two versions side-by-side** for comparison:

### Logfire Version
```
Python (Logfire) → OTLP (port 4318) → OTel Collector (port 8889) → Prometheus → Grafana
```

### Direct Prometheus Version
```
Python (prometheus_client) → HTTP (port 8001) → Prometheus → Grafana
```

**Components:**
- **main.py** (Logfire): Exports OpenTelemetry histogram metrics via OTLP to OTel Collector
- **main-prometheus.py** (Direct): Exposes native Prometheus metrics directly
- **OpenTelemetry Collector**: Receives OTLP metrics on port 4318, exposes in Prometheus format on port 8889
- **Prometheus**: Scrapes from both OTel Collector (port 8889) and Direct app (port 8001)
- **Grafana**: Visualizes both dashboards for comparison

## Prerequisites

- Python 3.12+
- Docker and Docker Compose
- uv (or pip for Python dependencies)
- just (optional, for convenient commands)

## Quick Start

### Complete Setup (Runs Both Versions for Comparison)

This demo runs **both** Logfire and Direct Prometheus versions simultaneously for comparison:

```bash
# 1. Install dependencies
just install

# 2. Setup infrastructure and Grafana
just setup

# 3. Run both apps simultaneously
just run

# 4. View dashboard links
just grafana
```

This runs:
- **Logfire version**: Exports via OTLP (port 4318) → OTel Collector (port 8889) → Prometheus
- **Direct version**: Exposes metrics on port 8001 → Prometheus directly

Both dashboards will be available in Grafana:
- **Histogram Demo (Logfire + OTel)**: http://localhost:3000/d/histogram-demo-logfire
- **Histogram Demo (Direct Prometheus)**: http://localhost:3000/d/histogram-demo-direct

Compare them side-by-side to verify if Logfire's histogram export is working correctly!

### Run Individual Versions

If you prefer to run only one version:

```bash
# Run just the Logfire version
just setup
just run-logfire

# Run just the Direct Prometheus version
just setup
just run-direct
```

### Automated Setup Details

The `just setup` command automatically:
- Starts Docker containers (OTel Collector, Prometheus, Grafana)
- Configures Prometheus data source in Grafana
- Imports **both** dashboards (Logfire and Direct versions)

**Useful commands:**
- `just` - Show all available commands
- `just setup` - Complete automated setup
- `just run` - Run both apps simultaneously (Ctrl+C to stop)
- `just run-logfire` - Run only the Logfire version
- `just run-direct` - Run only the Direct Prometheus version
- `just grafana` - Show Grafana dashboard links
- `just open-grafana` - Open Grafana login page in browser
- `just up` - Start Docker services
- `just down` - Stop Docker services
- `just logs` - View logs from all services
- `just otel-logs` - View OpenTelemetry Collector logs
- `just prometheus` - Open Prometheus in browser
- `just health` - Check if all services are running
- `just clean` - Stop everything and remove data

**Development commands:**
- `just lint` - Run ruff linter
- `just format` - Run ruff formatter
- `just check` - Run both linter and formatter

## How Logfire is Configured

The Logfire version (`main.py`) is configured to export metrics to a local OpenTelemetry Collector:

```python
import os
import logfire

# Configure OpenTelemetry to export to local OTel Collector
os.environ["OTEL_EXPORTER_OTLP_ENDPOINT"] = "http://localhost:4318"

# Configure Logfire to use OTLP exporter (not Logfire cloud)
logfire.configure(
    send_to_logfire=False,  # Don't send to Logfire cloud
    service_name="histogram-demo",
)
```

**Key points:**
- `OTEL_EXPORTER_OTLP_ENDPOINT` must be set **before** calling `logfire.configure()`
- The SDK automatically appends `/v1/metrics` and `/v1/traces` to the endpoint
- `send_to_logfire=False` disables sending to Logfire's cloud service
- Metrics flow: Logfire → OTLP (port 4318) → OTel Collector → Prometheus

### Manual Setup (Without Just)

#### 1. Install Python Dependencies

```bash
uv sync
```

#### 2. Start the Infrastructure

```bash
docker compose up -d
```

This starts:
- **OpenTelemetry Collector** at http://localhost:4318 (OTLP HTTP), http://localhost:8889 (Prometheus metrics)
- **Prometheus** at http://localhost:9090
- **Grafana** at http://localhost:3000 (username: `admin`, password: `admin`)

Wait a few seconds for services to initialize.

#### 3. Configure Grafana and Import Dashboards

```bash
./setup.sh
```

#### 4. Start the Applications

Run both versions:
```bash
# Terminal 1 - Logfire version
uv run python main.py

# Terminal 2 - Direct Prometheus version
uv run python main-prometheus.py
```

You should see output like:
```
Starting Logfire Histogram Demo
Exporting metrics via OpenTelemetry to OTel Collector (localhost:4318)
Prometheus will scrape from OTel Collector at localhost:8889/metrics

Simulating file uploads...
Uploaded small file: 245,123 bytes, duration: 0.35s
```

#### 5. Verify Metrics in Prometheus

1. Open http://localhost:9090
2. Go to **Graph** tab
3. Try these queries (note the `logfire_` namespace prefix from OTel Collector):
   - `logfire_uploaded_file_bytes_bucket` - See all histogram buckets
   - `logfire_uploaded_file_bytes_count` - Total number of uploads
   - `logfire_uploaded_file_bytes_sum` - Total bytes uploaded
   - `histogram_quantile(0.95, rate(logfire_uploaded_file_bytes_bucket[1m]))` - 95th percentile file size
   - `logfire_http_request_duration_seconds_bucket` - Request duration buckets

You should see metrics with labels like `file_type="small"`, `file_type="medium"`, etc.

## Grafana Dashboard

### Pre-built Dashboard (Automated)

If you used `just setup`, the dashboard is already imported! Access it at:
- http://localhost:3000/d/logfire-histogram/logfire-histogram-demo
- Or navigate to: **Dashboards → Browse → Logfire Histogram Demo**

The dashboard includes:
- **Total Uploads** - Count of all file uploads
- **Upload Rate** - Files uploaded per second
- **Average File Size** - Mean file size across all uploads
- **95th Percentile** - p95 file size with color-coded thresholds
- **File Size Percentiles Over Time** - p50, p95, p99 trends
- **Request Duration by File Type** - p95 latency breakdown
- **File Size Distribution** - Bar gauge showing cumulative buckets
- **Uploads by File Type** - Pie chart of distribution
- **Files by Type** - Breakdown stats
- **Heatmap** - File size distribution over time

### Manual Setup (Optional)

If you didn't use `just setup`, you can manually configure Grafana:

#### 1. Add Prometheus Data Source

Manually configure:
1. Open Grafana at http://localhost:3000
2. Go to **Connections → Data Sources**
3. Click **Add data source**
4. Select **Prometheus**
5. Set URL to `http://prometheus:9090`
6. Click **Save & Test**

#### 2. Import the Dashboard

Run the import script:
```bash
./import-dashboard.sh
```

Or manually:
1. Go to **Dashboards → Import**
2. Click **Upload JSON file**
3. Select `grafana-dashboard.json`
4. Click **Import**

### Creating Custom Visualizations

#### Stat Panel: Files Under 1MB

Shows how many files are under 1MB:

1. Create a new dashboard
2. Add **Stat** panel
3. Query: `logfire_uploaded_file_bytes_bucket{le="1e+06"}`
4. Set **Calculation** to **Last**

#### Bar Gauge: Bucket Distribution

Shows distribution across all buckets:

1. Add **Bar gauge** panel
2. Query: `logfire_uploaded_file_bytes_bucket`
3. Legend: `{{le}}`
4. Transform: **Format as** � **Heatmap**
5. Set **Calculation** to **Last** (not Mean)

This shows the cumulative distribution across buckets.

#### Heatmap: Distribution Over Time

Shows how file sizes change over time:

1. Add **Heatmap** panel
2. Query: `increase(logfire_uploaded_file_bytes_bucket[1m])`
3. **Format** � **Time series buckets**
4. Adjust **Max data points** to ~25 for better performance

#### Graph: Percentiles

Shows different percentiles over time:

1. Add **Graph** or **Time series** panel
2. Add multiple queries:
   - 50th percentile: `histogram_quantile(0.50, rate(logfire_uploaded_file_bytes_bucket[1m]))`
   - 95th percentile: `histogram_quantile(0.95, rate(logfire_uploaded_file_bytes_bucket[1m]))`
   - 99th percentile: `histogram_quantile(0.99, rate(logfire_uploaded_file_bytes_bucket[1m]))`
3. Legend: `p{{quantile}}`

## Understanding the Metrics

### How It Works

1. **Logfire** creates OpenTelemetry histogram metrics in Python
2. Metrics are exported via **OTLP** (OpenTelemetry Protocol) to the **OTel Collector**
3. The **OTel Collector** transforms and exposes metrics in Prometheus format
4. **Prometheus** scrapes the metrics from the OTel Collector
5. **Grafana** queries Prometheus to visualize the data

### Histogram Components

Each histogram metric generates three time series:

1. **`logfire_uploaded_file_bytes_bucket{le="N"}`**: Cumulative count of observations <= N
2. **`logfire_uploaded_file_bytes_sum`**: Sum of all observed values
3. **`logfire_uploaded_file_bytes_count`**: Total number of observations

The `logfire_` prefix comes from the namespace configured in the OTel Collector.

### OpenTelemetry vs Traditional Prometheus Histograms

**Logfire uses OpenTelemetry histograms**, which differ from traditional Prometheus histograms:
- OpenTelemetry histograms don't require explicit bucket configuration in code
- Buckets are determined by the backend (Prometheus in this case)
- Values use exponential notation (e.g., `le="1e+06"` for 1MB)
- Support for exponential histograms (more efficient bucket distribution)

### Buckets Are Cumulative

This is important: if you have 10 files under 500KB and 3 more between 500KB-1MB, the buckets will show:
- `le="5e+05"`: 10
- `le="1e+06"`: 13 (not 3!)

To get files in a specific range, subtract adjacent buckets.

### Quantile Calculation

The `histogram_quantile()` function estimates quantiles from histogram buckets using linear interpolation. For accurate results:
- OpenTelemetry automatically determines optimal bucket boundaries
- Use rate() to calculate quantiles over time windows
- Remember it's an estimate, not exact
## Example Queries

```promql
# Average file size
rate(logfire_uploaded_file_bytes_sum[5m]) / rate(logfire_uploaded_file_bytes_count[5m])

# 95th percentile file size (all files)
histogram_quantile(0.95, rate(logfire_uploaded_file_bytes_bucket[5m]))

# 95th percentile for small files only
histogram_quantile(0.95, rate(logfire_uploaded_file_bytes_bucket{file_type="small"}[5m]))

# Request duration by file type
histogram_quantile(0.95, rate(logfire_http_request_duration_seconds_bucket[5m])) by (file_type)

# Upload rate (files per second)
rate(logfire_uploaded_file_bytes_count[1m])
```

## Why Use Logfire?

**Pydantic Logfire** is an observability platform built on OpenTelemetry that provides:

- **Simple API**: Clean, Pythonic interface for creating metrics (no complex bucket configuration)
- **OpenTelemetry Native**: Built on open standards, export to any OTel-compatible backend
- **No Vendor Lock-in**: While Logfire offers a cloud platform, the SDK is open source and works with Grafana, Prometheus, or any OTel backend
- **Auto-instrumentation**: Easy integration with popular Python frameworks
- **Unified Observability**: Combine metrics, traces, and logs in one platform

In this demo, we use Logfire's SDK but export to self-hosted Grafana instead of Logfire's cloud, demonstrating the flexibility of OpenTelemetry.

## Stopping the Demo

```bash
# Stop the Python app
Ctrl+C

# Stop Docker services
docker compose down

# Remove volumes (to reset data)
docker compose down -v
```

## File Structure

```
.
├── main.py                       # Logfire version - exports via OpenTelemetry
├── main-prometheus.py            # Direct Prometheus version - native prometheus_client
├── docker-compose.yml            # Docker Compose (OTel Collector, Prometheus, Grafana)
├── prometheus.yml                # Prometheus config - scrapes from both sources
├── otel-collector-config.yml    # OpenTelemetry Collector configuration
├── grafana-dashboard.json        # Dashboard for Logfire version (logfire_* metrics)
├── grafana-dashboard-direct.json # Dashboard for Direct version (no prefix)
├── setup.sh                      # Complete setup script (Grafana + both dashboards)
├── .pre-commit-config.yaml       # Pre-commit hooks (ruff linter + formatter)
├── justfile                      # Just commands for easy task running
├── pyproject.toml                # Python dependencies + ruff config
└── README.md                     # This file
```

**Clean and simple!** Only essential files for running both comparison versions.

## Learn More

### Logfire & OpenTelemetry
- [Pydantic Logfire Documentation](https://logfire.pydantic.dev/docs/)
- [Logfire Metrics Guide](https://logfire.pydantic.dev/docs/guides/onboarding-checklist/add-metrics/)
- [OpenTelemetry Python](https://opentelemetry.io/docs/languages/python/)
- [OpenTelemetry Collector](https://opentelemetry.io/docs/collector/)

### Prometheus & Grafana
- [Prometheus Histograms Documentation](https://prometheus.io/docs/practices/histograms/)
- [Grafana Histogram Guide](https://grafana.com/blog/2020/06/23/how-to-visualize-prometheus-histograms-in-grafana/)
- [OpenTelemetry Collector Prometheus Exporter](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/exporter/prometheusexporter)
