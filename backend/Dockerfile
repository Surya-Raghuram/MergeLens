FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    && rm -rf /var/lib/apt/lists/*

# 1. Build the C++ Analyzer (Context is now root, so no '../')
COPY ./analyzer /app/analyzer
WORKDIR /app/analyzer
RUN mkdir build && cd build && \
    cmake .. && \
    make -j$(nproc)

# 2. Setup Python Backend
WORKDIR /app/backend
COPY ./backend/pyproject.toml .
RUN pip install --no-cache-dir .

# Copy application code
COPY ./backend/app /app/backend/app

# Ensure we are in the correct directory for uvicorn/arq
WORKDIR /app/backend

EXPOSE 8000