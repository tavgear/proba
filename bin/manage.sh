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
    echo "  build           - Build images"
    echo "  down            - Stop containers"
    echo "  restart         - Restart containers"
    echo "  pull            - Pull latest images (PROD only)"
    echo "  logs            - Show logs (tail 100)"
    echo "  ps              - List running containers"
    exit "$exit_code"
}

# 1. Загрузка переменных окружения
load_env() {
    local file=$1
    if [ -f "$file" ]; then
        # Читаем файл построчно, игнорируя комментарии и пустые строки
        while read -r line || [ -n "$line" ]; do
            # Убираем пробелы в начале и конце
            line=$(echo "$line" | xargs)
            # Пропускаем пустые строки и комментарии
            [[ -z "$line" ]] && continue
            [[ "$line" == "#"* ]] && continue
            
            # Парсим ключ и значение (поддерживаем и : и =)
            if [[ "$line" == *":"* ]]; then
                key=$(echo "${line%%:*}" | xargs)
                value=$(echo "${line#*:}" | xargs)
            elif [[ "$line" == *"="* ]]; then
                key=$(echo "${line%%=*}" | xargs)
                value=$(echo "${line#*=}" | xargs)
            else
                continue
            fi
            
            # Экспортируем переменную
            export "$key=$value"
        done < "$file"
    fi
}

load_env .env
load_env .env.local

# 2. Определение режима (dev по умолчанию)
MODE=${MODE:-dev}
DOMAIN=${DOMAIN:-localhost}

# Функция для вывода заголовка (аналогично Makefile)
print_header() {
    # Не выводим заголовок при помощи
    if [[ "$1" =~ ^(help|--help|-h)$ ]]; then return; fi
    
    echo "============================="
    echo "  PROJECT:       ${PROJECT_NAME:-project}"
    echo "  MODE:          $MODE"
    echo "  DOMAIN:        http://$DOMAIN"
    echo "============================="
}

# Вывод заголовка при запуске (кроме вызова помощи)
print_header "$1"

# 3. Проверка наличия .env.local (обязательно для всех команд, кроме help и init)
if [[ ! "$1" =~ ^(help|--help|-h|init)$ ]]; then
    if [ ! -f .env.local ]; then
        echo "Error: .env.local not found. Please run './bin/manage.sh init <dev|prod>' first."
        exit 1
    fi
fi

# 4. Формирование команды docker compose
COMPOSE="docker compose --env-file .env --env-file .env.local"

if [ "$MODE" == "dev" ]; then
    # В режиме разработки подключаем базовый и dev файлы
    COMPOSE="$COMPOSE -f compose.yaml -f compose.dev.yaml"
elif [ "$MODE" == "prod" ]; then
    # В режиме продакшена:
    # 1. Если есть compose.prod.yaml (локальная отладка), подключаем его явно
    if [ -f "compose.prod.yaml" ]; then
        COMPOSE="$COMPOSE -f compose.yaml -f compose.prod.yaml"
    fi
    # 2. Если его нет (сервер), не указываем файлы вообще. 
    # Docker автоматически подхватит compose.yaml и compose.override.yaml (если есть).
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
    if [ ! -f .env.local ]; then
        touch .env.local
    fi

    # Обновление режима в .env.local (игнорируя текущее значение)
    if grep -q "^MODE=" .env.local; then
        sed -i "s/^MODE=.*/MODE=dev/" .env.local
    else
        echo "MODE=dev" >> .env.local
    fi
    if grep -q "^MODE_NODE_ENV=" .env.local; then
        sed -i "s/^MODE_NODE_ENV=.*/MODE_NODE_ENV=development/" .env.local
    else
        echo "MODE_NODE_ENV=development" >> .env.local
    fi

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
    if [ -f ".env.local" ]; then
        echo "[!] Project is already initialized (found .env.local)."
        echo "    If you want to re-init with new secrets, please remove .env.local manually."
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
        echo "[!] .env.local already exists. Updating mode settings to PROD."
    # Обновление режима в .env.local
    if grep -q "^MODE=" .env.local; then
        sed -i "s/^MODE=.*/MODE=prod/" .env.local
    else
        echo "MODE=prod" >> .env.local
    fi
    if grep -q "^MODE_NODE_ENV=" .env.local; then
        sed -i "s/^MODE_NODE_ENV=.*/MODE_NODE_ENV=production/" .env.local
    else
        echo "MODE_NODE_ENV=production" >> .env.local
    fi
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
    build)
        $COMPOSE build ;;
    down)
        $COMPOSE down ;;
    restart)
        $COMPOSE restart ;;
    pull)
        if [ "$MODE" == "dev" ]; then
            echo "[!] 'pull' command is disabled in DEV mode."
            echo "    Use 'build' to rebuild images locally or 'up' to start project."
            exit 0
        fi
        $COMPOSE pull ;;
    logs)
        $COMPOSE logs -f --tail=100 ;;
    ps)
        $COMPOSE ps ;;
    *)
        usage 1 ;;
esac
