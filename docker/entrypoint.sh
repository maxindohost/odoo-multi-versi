#!/usr/bin/env bash
set -euo pipefail

DB_HOST="${DB_HOST:-db}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-odoo}"

echo "[entrypoint] Menunggu PostgreSQL di ${DB_HOST}:${DB_PORT} ..."
until pg_isready -q -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER"; do sleep 1; done

ODOO_BIN=/opt/odoo/odoo-bin

if [ "${DEBUGPY:-0}" = "1" ]; then
  wait_flag=()
  [ "${DEBUGPY_WAIT:-0}" = "1" ] && wait_flag=(--wait-for-client)
  echo "[entrypoint] Mode debug: debugpy mendengarkan di :5678"
  # auto-reload dimatikan saat debug (reload me-restart proses & memutus debugger)
  exec python -m debugpy --listen 0.0.0.0:5678 "${wait_flag[@]}" "$ODOO_BIN" "$@" --dev=qweb,xml
fi

exec python "$ODOO_BIN" "$@"
