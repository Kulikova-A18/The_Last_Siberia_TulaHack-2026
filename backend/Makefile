# backend/Makefile
.PHONY: help start stop restart logs test migrate init clean

help:
	@echo "Available commands:"
	@echo "  make start     - Start all services"
	@echo "  make stop      - Stop all services"
	@echo "  make restart   - Restart all services"
	@echo "  make logs      - View logs"
	@echo "  make test      - Run tests"
	@echo "  make migrate   - Run database migrations"
	@echo "  make init      - Initialize project"
	@echo "  make clean     - Clean project"

start:
	@bash scripts/start.sh

stop:
	@bash scripts/stop.sh

restart:
	@bash scripts/restart.sh

logs:
	@bash scripts/logs.sh

test:
	@pytest -v --cov=app --cov-report=term-missing

migrate:
	@bash scripts/migrate.sh

init:
	@pip install -r requirements.txt
	@cp .env.example .env || true
	@echo "Project initialized. Please edit .env file if needed."

clean:
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.pyc" -delete
	@rm -rf .pytest_cache .coverage htmlcov 2>/dev/null || true
	@echo "Cleaned project"