#!/bin/bash
# bin/manage.sh

set -e

# Функция для вывода помощи
usage() {
    local exit_code=${1:-0}
    echo "Usage: $0 [command]"
    echo "Commands:"
    echo "  init <dev|prod> [back|front] - Initialize project (folders, .env.local secrets)"
    echo "  up              - Start containers (detached)"
    echo "  down            - Stop containers"
    echo "  restart         - Restart containers"
    echo "  pull            - Pull latest images"
    echo "  logs            - Show logs (tail 100)"
    echo "  ps              - List running containers"
    exit "$exit_code"
}

# 1. Загрузка переменных окружения
if [ -f .env ]; then
    export "$(grep -v '^#' .env | xargs)"
fi
if [ -f .env.local ]; then
    export "$(grep -v '^#' .env.local | xargs)"
fi

# 2. Определение режима (dev по умолчанию)
MODE=${MODE:-dev}

# 3. Проверка наличия .env.local (обязательно для всех команд, кроме help и init)
if [[ ! "$1" =~ ^(help|--help|-h|init)$ ]]; then
    if [ ! -f .env.local ]; then
        echo "Error: .env.local not found. Please run './bin/manage.sh init <dev|prod>' first."
        exit 1
    fi
fi

# 4. Формирование команды docker compose
COMPOSE="docker compose --env-file .env"
# Мы знаем, что для всех команд кроме init .env.local существует. 
# Для init мы добавим его в COMPOSE позже, если он создастся, или будем использовать аккуратно.
if [ -f .env.local ]; then
    COMPOSE="$COMPOSE --env-file .env.local"
fi

# Добавляем базовый файл
COMPOSE="$COMPOSE -f compose.yaml"

# Добавляем специфичный для режима файл
# compose.prod.yaml - только для локальнгого тестирования прод-контейнеров
if [ "$MODE" == "dev" ]; then
    if [ -f "compose.dev.yaml" ]; then
        COMPOSE="$COMPOSE -f compose.dev.yaml"
    fi
elif [ "$MODE" == "prod" ]; then
    # На проде compose.prod.yaml не подключаем (он для локальных тестов)
    # На проде compose.override.yaml подхватывается докером автоматически, 
    # поэтому явно его здесь не указываем.
    :
fi

# Функция генерации секретов
generate_secrets() {
    # Для Strapi
    STRAPI_APP_KEYS=$(openssl rand -base64 16),$(openssl rand -base64 16),$(openssl rand -base64 16),$(openssl rand -base64 16)
    STRAPI_API_TOKEN_SALT=$(openssl rand -base64 16)
    STRAPI_ADMIN_JWT_SECRET=$(openssl rand -base64 16)
    STRAPI_JWT_SECRET=$(openssl rand -base64 24)
    STRAPI_TRANSFER_TOKEN_SALT=$(openssl rand -base64 16)
    STRAPI_ENCRYPTION_KEY=$(openssl rand -base64 16)
}

init_dev() {
    local target=${1:-all}
    echo "=== Initialization (DEV mode, target: $target) ==="
    
    # 0. Check if already initialized (only if target is all)
    if [ "$target" == "all" ]; then
        if [ -s ".env.local" ] && [ -d "back" ] && [ -d "front" ]; then
            echo "[!] Project is already initialized in DEV mode."
            echo "    - .env.local exists"
            echo "    - Directory 'back' exists"
            echo "    - Directory 'front' exists"
            echo "    If you want to re-init, please remove them manually (BE CAREFUL!)."
            exit 0
        fi
    fi

    # Системные файлы
    [ -f .env.local ] || touch .env.local

    # Инициализация бэкенда
    if [ "$target" == "all" ] || [ "$target" == "back" ]; then
        if [ -d "back" ]; then
            echo "[!] Directory 'back' already exists. Skipping Strapi init."
        else
            echo "START init back (Strapi)"
            echo "==============="
            docker run --rm -t -v ".:/app" -w /app node:24-slim \
                sh -lc '
                    set -eu;
                    npx -y create-strapi-app@latest back --skip-cloud --no-run --typescript --non-interactive;
                '
            echo "==============="
            echo "FINISH init back"
        fi
    fi

    # Инициализация фронтенда
    if [ "$target" == "all" ] || [ "$target" == "front" ]; then
        if [ -d "front" ]; then
            echo "[!] Directory 'front' already exists. Skipping Next.js init."
        else
            echo "START init front (Next.js)"
            echo "===================================="
            docker run --rm -t -v ".:/app" -w /app node:24-slim \
                sh -lc '
                    set -eu;
                    npx -y create-next-app@latest front --yes;
                    cd front;
                    sed -i "s/const nextConfig: NextConfig = {/const nextConfig: NextConfig = {\\n  output: '\''standalone'\'',/" next.config.ts;
                '
            echo "===================================="
            echo "FINISH init front"
        fi
    fi
}

init_prod() {
    echo "=== Initialization (PROD mode) ==="
    
    # 0. Check if already initialized
    if [ -f ".env.local" ] && [ -d "data/uploads" ] && [ -d "data/db" ]; then
        echo "[!] Project is already initialized in PROD mode."
        echo "    - .env.local exists"
        echo "    - Directory 'data/uploads' exists"
        echo "    - Directory 'data/db' exists"
        exit 0
    fi

    # 1. Скопировать базовый .env (если он нужен, но обычно он есть в репо)
    # По условию: "Скопировать из репо базовый енв-файл с настройками по умолчанию"
    # Вероятно имеется ввиду что если файла .env нет, его надо создать как копию .env.example или просто убедиться в его наличии.
    # Но так как .env уже есть в корне, я просто проверю его наличие.
    if [ ! -f ".env" ]; then
        echo "[!] Warning: .env file is missing. Please ensure it exists."
    fi

    # 2. Сформировать .env.local с секретами и переменными для ручной правки
    if [ ! -f ".env.local" ]; then
        echo "[+] Generating .env.local for PROD..."
        generate_secrets
        
        cat <<EOF > ".env.local"
# --- REQUIRED: EDIT MANUALLY ---
PROJECT_NAME=
GITHUB_USER_NAME=
DOMAIN=

# --- AUTO-GENERATED SECRETS ---
STRAPI_APP_KEYS=$STRAPI_APP_KEYS
STRAPI_API_TOKEN_SALT=$STRAPI_API_TOKEN_SALT
STRAPI_ADMIN_JWT_SECRET=$STRAPI_ADMIN_JWT_SECRET
STRAPI_JWT_SECRET=$STRAPI_JWT_SECRET
STRAPI_TRANSFER_TOKEN_SALT=$STRAPI_TRANSFER_TOKEN_SALT
STRAPI_ENCRYPTION_KEY=$STRAPI_ENCRYPTION_KEY

# --- DEFAULT SETTINGS ---
MODE=prod
MODE_NODE_ENV=production
EOF
        echo "[OK] .env.local created. PLEASE EDIT REQUIRED FIELDS!"
    else
        echo "[!] .env.local already exists. Skipping."
    fi
}

case "$1" in
    help|--help|-h)
        usage 0 ;;
    init)
        MODE_ARG=$2
        TARGET_ARG=${3:-all}

        if [ -z "$MODE_ARG" ]; then
            echo "Error: 'init' requires mode argument (dev|prod)."
            echo "Usage: $0 init <dev|prod> [back|front]"
            exit 1
        fi

        if [ "$MODE_ARG" == "dev" ]; then
            init_dev "$TARGET_ARG"
        elif [ "$MODE_ARG" == "prod" ]; then
            init_prod
        else
            echo "Unknown mode: $MODE_ARG. Use 'dev' or 'prod'."
            exit 1
        fi
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
        usage 1 ;;
esac
