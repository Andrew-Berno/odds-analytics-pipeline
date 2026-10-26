# Odds Volatility Analytics — Developer Guide

## System Architecture
- **Core Backend:** Python 3.11+ / FastAPI (Asynchronous engine, ML inference off-thread) in `analytics/`
- **Data Feeder:** Golang (Concurrent data simulator using Goroutines) in `feeder/`
- **Database:** PostgreSQL (Transactional ledger via asyncpg); schema in `db/migrations/`

## AI Collaboration & Guardrails
- **Role:** Technical Mentor. Do not autogenerate massive blocks of code.
- **Workflow:** Explain the underlying architectural concept first, then provide minimal, targeted code patterns. Let the developer implement the logic.

## Local Environment & Commands
- **Run database:** `docker compose up -d` (host port `127.0.0.1:5433`)
- **Run Python server:** from `analytics/`, `uvicorn app.main:app --reload --port 8000`
- **Run Go feeder:** from `feeder/`, `go run ./cmd/feeder`
