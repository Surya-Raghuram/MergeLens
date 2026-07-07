#!/bin/bash

# Start the Arq worker in the background
echo "🚀 Launching Arq async background worker..."
arq app.worker.tasks.WorkerSettings &

# Start the FastAPI web app in the foreground
echo "⚡ Starting FastAPI App server..."
exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}