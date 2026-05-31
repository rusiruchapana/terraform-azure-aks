import os
import random
import time

from fastapi import FastAPI, Response
from opentelemetry import metrics, trace
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor

SERVICE_NAME = os.getenv("OTEL_SERVICE_NAME", "practitioner-otel-app")

app = FastAPI(title="Practitioner OpenTelemetry App")

FastAPIInstrumentor.instrument_app(app)

meter = metrics.get_meter(SERVICE_NAME)
tracer = trace.get_tracer(SERVICE_NAME)

request_counter = meter.create_counter(
    name="practitioner_http_requests_total",
    description="Total HTTP requests handled by the sample app",
    unit="1",
)

work_duration = meter.create_histogram(
    name="practitioner_work_duration_seconds",
    description="Simulated work duration",
    unit="s",
)


@app.get("/")
def root():
    request_counter.add(1, {"route": "/", "status": "success"})
    return {
        "message": "Hello from the OpenTelemetry sample app",
        "service": SERVICE_NAME,
    }


@app.get("/health")
def health():
    request_counter.add(1, {"route": "/health", "status": "success"})
    return {"status": "ok"}


@app.get("/work")
def work():
    with tracer.start_as_current_span("simulate-work"):
        duration = random.uniform(0.05, 0.5)
        time.sleep(duration)
        request_counter.add(1, {"route": "/work", "status": "success"})
        work_duration.record(duration, {"route": "/work"})
        return {
            "message": "work completed",
            "duration_seconds": duration,
        }


@app.get("/error")
def error(response: Response):
    with tracer.start_as_current_span("simulate-error"):
        request_counter.add(1, {"route": "/error", "status": "error"})
        response.status_code = 500
        return {
            "message": "simulated error",
        }
