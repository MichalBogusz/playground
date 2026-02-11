.PHONY: help up down restart logs ps clean dashboard

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

up: ## Start all services
	docker compose up -d

down: ## Stop all services
	docker compose down

restart: ## Restart all services
	docker compose restart

logs: ## Show logs from all services (follow mode)
	docker compose logs -f

ps: ## Show status of all services
	docker compose ps

clean: ## Stop services and remove volumes
	docker compose down -v

dashboard: ## Open Traefik dashboard in browser
	@echo "Opening Traefik dashboard at http://traefik.localhost/dashboard/"
	@xdg-open http://traefik.localhost/dashboard/ 2>/dev/null || open http://traefik.localhost/dashboard/ 2>/dev/null || echo "Please open http://traefik.localhost/dashboard/ manually"

whoami: ## Test whoami service
	@echo "\n=== Testing whoami service ==="
	@curl -s http://whoami.localhost
	@echo "\n"
