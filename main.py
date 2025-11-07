"""
Logfire Histogram Demo with OpenTelemetry

This application simulates file uploads with varying sizes and exports
histogram metrics via OpenTelemetry to Grafana/Prometheus.
"""

import os
import random
import time

import logfire

# Set random seed for reproducible data generation
# This ensures both main.py and main-prometheus.py generate the same data
random.seed(42)

# Configure OpenTelemetry to export to local OTel Collector
# The SDK will automatically append /v1/traces and /v1/metrics to this URL
os.environ["OTEL_EXPORTER_OTLP_ENDPOINT"] = "http://localhost:4318"
# Explicitly enable OTLP exporter for metrics
os.environ["OTEL_METRICS_EXPORTER"] = "otlp"
# Set metric export interval to 5 seconds (default is 60s)
os.environ["OTEL_METRIC_EXPORT_INTERVAL"] = "5000"  # milliseconds

# Configure Logfire to use OTLP exporter (not Logfire cloud)
logfire.configure(
    send_to_logfire=False,  # Don't send to Logfire cloud
    service_name="histogram-demo",
)

# Create a counter metric for total uploads
upload_counter = logfire.metric_counter(
    "file_uploads_total",
    unit="1",
    description="Total number of file uploads",
)

# Create a histogram metric for file upload sizes
# Note: Logfire uses OpenTelemetry histograms which don't have explicit buckets
# The buckets are determined by the backend (Prometheus in this case)
uploaded_file_bytes = logfire.metric_histogram(
    "uploaded_file_bytes",
    unit="bytes",
    description="Size of uploaded files in bytes",
)

# Create another histogram for request duration
request_duration_seconds = logfire.metric_histogram(
    "http_request_duration_seconds",
    unit="s",
    description="HTTP request latency in seconds",
)


def simulate_file_upload():
    """Simulate a file upload with random size"""
    # Generate random file sizes with different distributions
    file_type = random.choices(
        ["small", "medium", "large", "very_large"], weights=[50, 30, 15, 5]
    )[0]

    if file_type == "small":
        # Small files: 10KB to 500KB
        size = random.randint(10_000, 500_000)
    elif file_type == "medium":
        # Medium files: 500KB to 5MB
        size = random.randint(500_000, 5_000_000)
    elif file_type == "large":
        # Large files: 5MB to 50MB
        size = random.randint(5_000_000, 50_000_000)
    else:
        # Very large files: 50MB to 100MB
        size = random.randint(50_000_000, 100_000_000)

    # Increment the upload counter
    upload_counter.add(1, attributes={"file_type": file_type})

    # Record the observation using Logfire
    uploaded_file_bytes.record(size, attributes={"file_type": file_type})

    # Simulate request duration based on file size
    duration = 0.1 + (size / 10_000_000) + random.uniform(0, 0.5)
    request_duration_seconds.record(duration, attributes={"file_type": file_type})

    print(f"Uploaded {file_type} file: {size:,} bytes, duration: {duration:.2f}s")


def main():
    print("Starting Logfire Histogram Demo")
    print("Exporting metrics via OpenTelemetry to OTel Collector (localhost:4318)")
    print("Prometheus will scrape from OTel Collector at localhost:8889/metrics")

    print("\nSimulating file uploads...")

    # Continuously simulate file uploads
    try:
        while True:
            simulate_file_upload()
            # Random delay between uploads (0.5 to 2 seconds)
            time.sleep(random.uniform(0.5, 2.0))
    except KeyboardInterrupt:
        print("\nShutting down...")
        logfire.shutdown()


if __name__ == "__main__":
    main()
