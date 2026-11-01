#!/usr/bin/env bash
# Runs after the numbered .sql migrations (900_ sorts last). Shell init
# scripts can read container env; .sql files cannot. Compose passes
# LEDGER_APP_PASSWORD from the project .env into this container.
set -euo pipefail

if [[ -z "${LEDGER_APP_PASSWORD:-}" ]]; then
  echo "LEDGER_APP_PASSWORD is not set" >&2
  exit 1
fi

psql -v ON_ERROR_STOP=1 -v pw="$LEDGER_APP_PASSWORD" \
    --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-'EOSQL'
    ALTER ROLE ledger_app WITH PASSWORD :'pw';
EOSQL
