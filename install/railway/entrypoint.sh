#!/bin/bash
set -e

CONFIG_DIR="${CONFIG_DIR:-/opt/config}"
CONFIG="$CONFIG_DIR/config.json"

mkdir -p "$CONFIG_DIR"

if [ ! -f "$CONFIG" ]; then
    echo "==> First run: generating config.json from Railway environment..."

    # Railway PostgreSQL plugin provides individual PG* vars
    DB_HOST="${PGHOST:-localhost}"
    DB_PORT="${PGPORT:-5432}"
    DB_NAME="${PGDATABASE:-nodebb}"
    DB_USER="${PGUSER:-nodebb}"
    DB_PASS="${PGPASSWORD:-nodebb}"

    # Use fixed NODEBB_SECRET env var in Railway for session stability!
    SECRET="${NODEBB_SECRET:-$(openssl rand -hex 32)}"

    cat > "$CONFIG" << JSONEOF
{
    "url": "${NODEBB_URL}",
    "secret": "${SECRET}",
    "database": "postgres",
    "postgres": {
        "host": "${DB_HOST}",
        "port": ${DB_PORT},
        "database": "${DB_NAME}",
        "username": "${DB_USER}",
        "password": "${DB_PASS}"
    },
    "port": 4567
}
JSONEOF

    echo "==> Running NodeBB setup (creates DB schema + admin account)..."
    /usr/src/app/nodebb setup \
        --config="$CONFIG" \
        --setup="{
            \"admin:username\": \"${NODEBB_ADMIN_USERNAME:-admin}\",
            \"admin:email\": \"${NODEBB_ADMIN_EMAIL}\",
            \"admin:password\": \"${NODEBB_ADMIN_PASSWORD}\",
            \"admin:password:confirm\": \"${NODEBB_ADMIN_PASSWORD}\"
        }"

    echo "==> Setup complete."
fi

exec /usr/local/bin/entrypoint.sh "$@"
