#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Production Startup Script for Vyapar Mitra Backend
# ==============================================================================

PORT="${PORT:-8000}"
WEB_CONCURRENCY="${WEB_CONCURRENCY:-4}"
LOG_LEVEL="${LOG_LEVEL:-info}"

echo "Starting Vyapar Mitra Backend on port ${PORT} with ${WEB_CONCURRENCY} workers (env: ${ENVIRONMENT:-production})..."

exec uvicorn app.main:app \
    --host 0.0.0.0 \
    --port "${PORT}" \
    --workers "${WEB_CONCURRENCY}" \
    --log-level "${LOG_LEVEL}" \
    --no-access-log
