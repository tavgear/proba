#!/bin/bash
# bin/manage.sh

set -e

# Функция для вывода помощи
usage() {
    echo "Usage: $0 [command]"
    echo "Commands:"
    echo "  init      - Initialize project (folders, .env.local secrets)"
    echo "  up        - Start containers (detached)"
    echo "  down      - Stop containers"
    echo "  restart   - Restart containers"
    echo "  pull      - Pull latest images"
    echo "  logs      - Show logs (tail 100)"
    echo "  ps        - List running containers"
    exit 1
}

# Команда docker compose с учетом всех нужных файлов
# На проде при деплое мы переименовываем compose.deploy.override.yaml в compose.override.yaml
COMPOSE="docker compose -f compose.yaml"
if [ -f "compose.override.yaml" ]; then
    COMPOSE="$COMPOSE -f compose.override.yaml"
fi

case "$1" in
    init)
        echo "=== Initialization ==="
        if [ ! -f ".env.local" ]; then
            echo "[+] Generating .env.local with secrets..."
            
            # Генерация секретов для Strapi
            # Используем openssl для генерации надежных ключей
            STRAPI_APP_KEYS=$(openssl rand -base64 32),$(openssl rand -base64 32),$(openssl rand -base64 32),$(openssl rand -base64 32)
            STRAPI_API_TOKEN_SALT=$(openssl rand -base64 32)
            STRAPI_ADMIN_JWT_SECRET=$(openssl rand -base64 32)
            STRAPI_JWT_SECRET=$(openssl rand -base64 32)
            STRAPI_TRANSFER_TOKEN_SALT=$(openssl rand -base64 32)
            STRAPI_ENCRYPTION_KEY=$(openssl rand -base64 32)

            cat <<EOF > ".env.local"
# --- REQUIRED: EDIT MANUALLY ---
PROJECT_NAME=my-awesome-project
GITHUB_USER_NAME=your-github-user
DOMAIN=example.com

# --- AUTO-GENERATED SECRETS ---
STRAPI_APP_KEYS=$STRAPI_APP_KEYS
STRAPI_API_TOKEN_SALT=$STRAPI_API_TOKEN_SALT
STRAPI_ADMIN_JWT_SECRET=$STRAPI_ADMIN_JWT_SECRET
STRAPI_JWT_SECRET=$STRAPI_JWT_SECRET
STRAPI_TRANSFER_TOKEN_SALT=$STRAPI_TRANSFER_TOKEN_SALT
STRAPI_ENCRYPTION_KEY=$STRAPI_ENCRYPTION_KEY

# --- OPTIONAL OVERRIDES ---
MODE=prod
MODE_NODE_ENV=production
EOF
            echo "[OK] .env.local created. PLEASE EDIT REQUIRED FIELDS!"
        else
            echo "[!] .env.local already exists. Skipping."
        fi
        
        # Создание необходимых папок для volumes
        mkdir -p data/uploads data/db
        echo "[OK] Directories created."
        ;;
    up)
        $COMPOSE up -d --remove-orphans ;;
    down)
        $COMPOSE down ;;
    restart)
        $COMPOSE restart ;;
    pull)
        $COMPOSE pull ;;
    logs)
        $COMPOSE logs -f --tail=100 ;;
    ps)
        $COMPOSE ps ;;
    *)
        usage ;;
esac
