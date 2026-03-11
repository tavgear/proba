# Blank Template (Next.js + Strapi + Caddy)

Это готовая заготовка для монорепозитория, включающая фронтенд на Next.js, бэкенд на Strapi и прокси-сервер Caddy.

## Быстрый старт (Разработка)

1.  **Подготовка окружения**:
    Скопируйте примеры файлов окружения:
    ```bash
    cp front/.env.example front/.env.local
    cp back/.env.example back/.env
    ```
    *Примечание: Для Strapi в `back/.env` рекомендуется заменить значения `tobemodified` на реальные секретные ключи.*

2.  **Запуск проекта**:
    Выполните команду в корневой директории:
    ```bash
    make dev
    ```
    Эта команда соберет Docker-образы и запустит контейнеры в режиме горячей перезагрузки (Hot Reload).

3.  **Проверка работы**:
    - **Frontend (Next.js)**: [http://localhost](http://localhost)
    - **Admin Panel (Strapi)**: [http://localhost/admin](http://localhost/admin)
    - **API (Strapi)**: [http://localhost/api](http://localhost/api)

## Доступные команды (Makefile)

- `make init` — Инициализация проектов (если папки `front` и `back` еще не созданы).
- `make dev` — Запуск всего стека в режиме разработки.
- `make build` — Сборка образов для продакшна.
- `make stop` — Остановка всех сервисов.
- `make ps` — Просмотр статуса запущенных контейнеров.
- `make audit` — Проверка зависимостей на уязвимости.

## Структура проекта

- `front/` — Приложение Next.js (App Router, Tailwind, TypeScript).
- `back/` — CMS Strapi (SQLite, TypeScript).
- `Caddyfile` — Конфигурация прокси-сервера.
- `docker-compose.yml` — Оркестрация сервисов.
