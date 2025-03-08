# Makefile for Harbor Infrastructure

.PHONY: help init apply-dev apply-staging apply-prod destroy-dev destroy-staging destroy-prod update-dependencies cleanup

# Default environment
ENV ?= dev

help:
	@echo "Harbor Infrastructure Management"
	@echo ""
	@echo "Usage:"
	@echo "  make init                  Initialize the repository"
	@echo "  make update-dependencies   Update module dependencies for an environment"
	@echo "  make apply-dev             Deploy to dev environment"
	@echo "  make apply-staging         Deploy to staging environment"
	@echo "  make apply-prod            Deploy to production environment"
	@echo "  make destroy-dev           Destroy dev environment"
	@echo "  make destroy-staging       Destroy staging environment"
	@echo "  make destroy-prod          Destroy production environment (requires confirmation)"
	@echo "  make cleanup ENV=<env>     Create cleanup module for pre-destroy operations"
	@echo ""
	@echo "Options:"
	@echo "  ENV=<env>                  Specify environment (dev, staging, prod)"

# Initialize the repository
init:
	@echo "Initializing Harbor Infrastructure Repository..."
	@chmod +x scripts/*.sh
	@mkdir -p logs
	@echo "Initialization complete!"

# Update module dependencies
update-dependencies:
	@echo "Updating dependencies for $(ENV) environment..."
	@chmod +x scripts/update-dependencies.sh
	@scripts/update-dependencies.sh $(ENV)

# Create cleanup module
cleanup:
	@echo "Creating cleanup module for $(ENV) environment..."
	@chmod +x scripts/update-dependencies.sh
	@scripts/update-dependencies.sh $(ENV) --create-cleanup

# Apply environments
apply-dev:
	@echo "Deploying Harbor Infrastructure to DEV environment..."
	@chmod +x scripts/deploy.sh
	@scripts/deploy.sh dev

apply-staging:
	@echo "Deploying Harbor Infrastructure to STAGING environment..."
	@chmod +x scripts/deploy.sh
	@scripts/deploy.sh staging

apply-prod:
	@echo "ATTENTION: You are about to deploy to PRODUCTION environment!"
	@read -p "Are you sure you want to proceed? (y/n) " -n 1 -r; \
	echo ""; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "Deploying Harbor Infrastructure to PRODUCTION environment..."; \
		chmod +x scripts/deploy.sh; \
		scripts/deploy.sh prod; \
	else \
		echo "Deployment canceled."; \
	fi

# Destroy environments
destroy-dev:
	@echo "Destroying Harbor Infrastructure in DEV environment..."
	@chmod +x scripts/destroy.sh
	@scripts/destroy.sh dev

destroy-staging:
	@echo "ATTENTION: You are about to destroy the STAGING environment!"
	@read -p "Are you sure you want to proceed? (y/n) " -n 1 -r; \
	echo ""; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "Destroying Harbor Infrastructure in STAGING environment..."; \
		chmod +x scripts/destroy.sh; \
		scripts/destroy.sh staging; \
	else \
		echo "Destruction canceled."; \
	fi

destroy-prod:
	@echo "ATTENTION: You are about to destroy the PRODUCTION environment!"
	@echo "This action is irreversible and will delete all data!"
	@read -p "Type 'destroy-production' to confirm: " confirm; \
	if [ "$$confirm" = "destroy-production" ]; then \
		echo "Destroying Harbor Infrastructure in PRODUCTION environment..."; \
		chmod +x scripts/destroy.sh; \
		scripts/destroy.sh prod; \
	else \
		echo "Destruction canceled. Confirmation did not match."; \
	fi

# Force destroy - only use in emergencies
force-destroy-dev:
	@echo "FORCE destroying DEV environment..."
	@chmod +x scripts/destroy.sh
	@scripts/destroy.sh dev --force

force-destroy-staging:
	@echo "ATTENTION: You are about to FORCE destroy the STAGING environment!"
	@read -p "Are you sure you want to proceed? (y/n) " -n 1 -r; \
	echo ""; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "FORCE destroying STAGING environment..."; \
		chmod +x scripts/destroy.sh; \
		scripts/destroy.sh staging --force; \
	else \
		echo "Destruction canceled."; \
	fi