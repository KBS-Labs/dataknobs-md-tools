.PHONY: test lint typecheck check fix sync

## Run all checks: lint, typecheck, test
check: lint typecheck test

## Run Python unit tests
test:
	uv run pytest tests/ -v

## Run ruff linter
lint:
	uv run ruff check src/python/ tests/

## Run mypy type checker
typecheck:
	uv run mypy src/python/

## Auto-fix lint issues and format
fix:
	uv run ruff check --fix src/python/ tests/
	uv run ruff format src/python/ tests/

## Install/sync all dependencies including dev
sync:
	uv sync --extra dev
