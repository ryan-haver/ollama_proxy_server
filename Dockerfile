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

# Set working directory for app
WORKDIR /home/app

# Copy application files
COPY ./app ./app
COPY gunicorn_conf.py .

# Set a non-root user and fix permissions
RUN addgroup --system app && adduser --system --group app && \
    chown -R app:app /home/app

USER app

# Expose the port the app runs on
EXPOSE 8080

# Command to run the application using our custom Gunicorn config file.
# This ensures structured JSON logging is used in production.
CMD ["gunicorn", "-c", "./gunicorn_conf.py", "app.main:app"]
