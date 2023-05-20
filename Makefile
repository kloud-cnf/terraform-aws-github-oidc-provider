help:
	@printf "Usage: make [target]\nTargets:\n"
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "    \033[36m%-30s\033[0m %s\n", $$1, $$2}'

install: ## Install repo dependencies
	@pre-commit install
	@pre-commit gc

uninstall: ## Uninstall repo dependencies
	@pre-commit uninstall

validate: ## Validate files with pre-commit hooks
	@pre-commit run --all-files
