#!/bin/bash
# bin/verify.sh
# Вспомогательный скрипт для безопасной проверки команд bin/manage.sh

# 1. Заглушки для основных команд
docker() { echo "[SANDBOX] docker $*"; }
sed()    { echo "[SANDBOX] sed $*"; }
touch()  { echo "[SANDBOX] touch $*"; }
cat()    {
    # Простая имитация cat для <<EOF
    if [[ "$*" == *"> .env.local"* ]]; then
        echo "[SANDBOX] Generating .env.local content..."
    else
        echo "[SANDBOX] cat $*"
    fi
}

# Экспортируем функции, чтобы manage.sh их увидел
export -f docker sed touch cat

echo "--- STARTING VERIFY MODE (SANDBOX) ---"
echo "Command to test: ./bin/manage.sh $*"
echo "--------------------------------------"

# 2. Запуск основного скрипта через source, чтобы функции-заглушки сработали
# Передаем все аргументы ($@)
source "$(dirname "$0")/manage.sh" "$@"

echo "--------------------------------------"
echo "--- VERIFY MODE FINISHED ---"
