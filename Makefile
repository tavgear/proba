.ONESHELL:
.PHONY: help generate-env-prod generate-env-dev sys-init init init-back init-front build up down ps

include .env
-include .env.local
export

UID := $(shell id -u)
GID := $(shell id -g)
PROJECT_DIR := $(shell pwd)

define print_header
	@echo "============================="
	@echo "  $(PROJECT_NAME)"
	@echo "============================="
	@echo "  MODE:          $(MODE)"
	@echo "  NODE_ENV:      $(MODE_NODE_ENV)"
	@echo "  DOMAIN:        http://$(DOMAIN)"
	@echo "============================="
endef

help:
	$(call print_header)
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

sys-init:
	@[ -f .env.local ] || touch .env.local

init: sys-init init-back init-front ## Initialize project

generate-env-dev: ## Generate local environments
	@if [ -f .env.local ]; then
		echo ".env.local already exists"
	else
		echo "MODE=prod" > .env.local
		echo "MODE_NODE_ENV=production" >> .env.local
		echo "" >> .env.local
		echo "APP_KEYS=$$(openssl rand -base64 16),$$(openssl rand -base64 16),$$(openssl rand -base64 16),$$(openssl rand -base64 16)" >> .env.local
		echo "API_TOKEN_SALT=$$(openssl rand -base64 16)" >> .env.local
		echo "ADMIN_JWT_SECRET=$$(openssl rand -base64 16)" >> .env.local
		echo "JWT_SECRET=$$(openssl rand -base64 24)" >> .env.local
		echo "TRANSFER_TOKEN_SALT=$$(openssl rand -base64 16)" >> .env.local
		echo "ENCRYPTION_KEY=$$(openssl rand -base64 16)" >> .env.local
		echo ".env.local generated!"
	fi

generate-env-prod: ## Generate local environments
	@if [ -f .env.local ]; then
		echo ".env.local already exists"
	else
		echo "PROJECT_NAME=" > .env.local
		echo "GITHUB_USER_NAME=" >> .env.local
		echo "" >> .env.local
		echo "MODE=prod" >> .env.local
		echo "MODE_NODE_ENV=production" >> .env.local
		echo "" >> .env.local
		echo "APP_KEYS=$$(openssl rand -base64 16),$$(openssl rand -base64 16),$$(openssl rand -base64 16),$$(openssl rand -base64 16)" >> .env.local
		echo "API_TOKEN_SALT=$$(openssl rand -base64 16)" >> .env.local
		echo "ADMIN_JWT_SECRET=$$(openssl rand -base64 16)" >> .env.local
		echo "JWT_SECRET=$$(openssl rand -base64 24)" >> .env.local
		echo "TRANSFER_TOKEN_SALT=$$(openssl rand -base64 16)" >> .env.local
		echo "ENCRYPTION_KEY=$$(openssl rand -base64 16)" >> .env.local
		echo ".env.local generated!"
	fi

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
				npx -y create-next-app@latest front --yes; \
				cd front; \
				sed -i "s/const nextConfig: NextConfig = {/const nextConfig: NextConfig = {\\n  output: '\''standalone'\'',/" next.config.ts; \
			'
		echo "===================================="
		echo "FINISH init front"
	fi

audit: ## Audit dependencies
	@echo "=== Audit back ==="
#	cd back && npm audit --production
#	@echo "=== Audit front ==="
#	cd front && npm audit

build:  ## Build docker compose (.env, .env.local)
	$(call print_header)
	docker compose --env-file .env --env-file .env.local -f compose.yaml -f compose.$(MODE).yaml build

up:  ## Up docker compose (.env, .env.local)
	$(call print_header)
	docker compose --env-file .env --env-file .env.local -f compose.yaml -f compose.$(MODE).yaml up -d --build

down:  ## Down docker compose (.env, .env.local)
	$(call print_header)
	docker compose --env-file .env --env-file .env.local -f compose.yaml -f compose.$(MODE).yaml down

run:  ## Run & enter docker compose (.env, .env.local)
	@if [ -z "$(word 2,$(MAKECMDGOALS))" ]; then \
  		echo "Use: make run <service>"; \
	else \
		docker compose --env-file .env --env-file .env.local -f compose.yaml -f compose.$(MODE).yaml run --rm -it $(word 2,$(MAKECMDGOALS)) sh; \
	fi

ps:  ## Docker processes
	$(call print_header)
	docker ps

%:
    @: