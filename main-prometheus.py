"""
Direct Prometheus Histogram Demo (without Logfire)

This application simulates file uploads with varying sizes and exposes
histogram metrics directly for Prometheus to scrape.
"""

import random
import time

from prometheus_client import Counter, Histogram, start_http_server

# Set random seed for reproducible data generation
# This ensures both main.py and main-prometheus.py generate the same data
random.seed(42)

# Create a counter metric for total uploads
upload_counter = Counter(
    "file_uploads_total",
    "Total number of file uploads",
    labelnames=["file_type"],
)

# Create a histogram metric for file upload sizes
# Explicit buckets for better visualization
uploaded_file_bytes = Histogram(
    "uploaded_file_bytes",
    "Size of uploaded files in bytes",
    labelnames=["file_type"],
    buckets=[
        100_000,
        500_000,
        1_000_000,
        5_000_000,
        10_000_000,
        50_000_000,
        100_000_000,
    ],
)

# Create another histogram for request duration
request_duration_seconds = Histogram(
    "http_request_duration_seconds",
    "HTTP request latency in seconds",
    labelnames=["file_type"],
    buckets=[0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0],
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
    upload_counter.labels(file_type=file_type).inc()

    # Record the observation with label
    uploaded_file_bytes.labels(file_type=file_type).observe(size)

    # Simulate request duration based on file size
    duration = 0.1 + (size / 10_000_000) + random.uniform(0, 0.5)
    request_duration_seconds.labels(file_type=file_type).observe(duration)

    print(f"Uploaded {file_type} file: {size:,} bytes, duration: {duration:.2f}s")


def main():
    print("Starting Direct Prometheus Histogram Demo")
    print("Metrics available at http://localhost:8001/metrics")
    print("Prometheus will scrape directly from this endpoint")

    # Start the Prometheus metrics server on port 8001
    start_http_server(8001)

    print("\nSimulating file uploads...")

    # Continuously simulate file uploads
    try:
        while True:
            simulate_file_upload()
            # Random delay between uploads (0.5 to 2 seconds)
            time.sleep(random.uniform(0.5, 2.0))
    except KeyboardInterrupt:
        print("\nShutting down...")


if __name__ == "__main__":
    main()
