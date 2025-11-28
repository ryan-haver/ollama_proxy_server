# --- Build Stage ---
FROM python:3.13-slim AS builder

# Set working directory
WORKDIR /app

# Install build dependencies needed for psutil and other packages
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

# Allow PUID/PGID to be passed as build args (for Unraid compatibility)
ARG PUID=1000
ARG PGID=1000

# Create user and group first
RUN addgroup --gid ${PGID} --system app && \
    adduser --uid ${PUID} --system --group app

# Set working directory for app
WORKDIR /home/app

# Copy application files (as root, before switching user)
COPY --chown=app:app ./app ./app
COPY --chown=app:app gunicorn_conf.py .

# Switch to non-root user
USER app

# Expose the port the app runs on
EXPOSE 8080

# Command to run the application using gunicorn (production-ready)
# This matches upstream's deployment method and ensures structured JSON logging
CMD ["gunicorn", "-c", "./gunicorn_conf.py", "app.main:app"]
