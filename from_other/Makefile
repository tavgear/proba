.ONESHELL:
.PHONY: help init init-back init-front dev build stop audit ps

dev: ## Start development mode
	docker compose up --build

build: ## Build production images
	NODE_ENV=production docker compose build

stop: ## Stop all services
	docker compose down

UID := $(shell id -u)
GID := $(shell id -g)
PROJECT_DIR := $(shell pwd)

help:
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

init: init-back init-front ## Initialize project

init-back: ## Init backend
	@if [ -d "back" ]; then
		echo "Back already exists"
	else
		echo "START init back"
		echo "==============="
		docker run --rm -t -v "$(PROJECT_DIR):/app" -w /app --user "$(UID):$(GID)" node:24-slim \
			sh -lc '\
				set -eu; \
				npx -y create-strapi-app@latest back --skip-cloud --no-run --typescript --non-interactive; \
			'
		echo "==============="
		echo "FINISH init back"
	fi

init-front: ## Init frontend
	@if [ -d "front" ]; then
		echo "Front already exists"
	else
		echo "START init front"
		echo "===================================="
		docker run --rm -t -v "$(PROJECT_DIR):/app" -w /app --user "$(UID):$(GID)" node:24-slim \
			sh -lc '\
				set -eu; \
				npx -y create-next-app@latest front --typescript --tailwind --eslint --app --src-dir --import-alias "@/*" --react-compiler; \
				cd front; \
				sed -i "s/const nextConfig: NextConfig = {/const nextConfig: NextConfig = {\\n  output: '\''standalone'\'',/" next.config.ts; \
			'
		echo "===================================="
		echo "FINISH init front"
	fi

audit: ## Audit dependencies
	@echo "=== Audit back ==="
	cd back && npm audit --production
	@echo "=== Audit front ==="
	cd front && npm audit

ps:  ## Docker processes
	@docker ps
