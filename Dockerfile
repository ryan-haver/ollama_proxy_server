# --- Build Stage ---
FROM python:3.13-slim AS builder

# Set working directory
WORKDIR /app

# Install build dependencies for ARM64 compatibility (psutil compilation)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Install poetry
RUN pip install poetry gunicorn

# Copy only dependency-defining files
COPY pyproject.toml ./

# Install dependencies, without dev dependencies, into a virtual environment
RUN poetry config virtualenvs.create false && \
    poetry install --without dev --no-root --no-interaction --no-ansi

# Set working directory
WORKDIR /home/app

# Copy application files (as root, before creating user)
COPY ./app ./app
COPY gunicorn_conf.py .

# Allow PUID/PGID to be passed as build args (for Unraid compatibility)
ARG PUID=1000
ARG PGID=1000

# Create user and group with configurable UID/GID
RUN addgroup --gid ${PGID} --system app && \
    adduser --uid ${PUID} --system --group app

# Create runtime directories and set ownership
RUN mkdir -p .ssl benchmarks app/static/uploads && \
    chown -R app:app /home/app

# Switch to non-root user
USER app

# Expose the port the app runs on
EXPOSE 8080

# Command to run the application using our custom Gunicorn config file.
# This ensures structured JSON logging is used in production.
CMD ["gunicorn", "-c", "./gunicorn_conf.py", "app.main:app"]
