# Demo orchestration. The instructor demo requires that the entire cloud
# environment can be destroyed and restored from this code in minutes.
#
# Tested flow:
#   make destroy   # tears everything down (preserves Firestore data + WIF)
#   make restore   # rebuilds and verifies (~15 min wall-clock)
#
# Individual targets are also runnable standalone for partial recovery.

PROJECT       ?= swe455-urlshortener-252
REGION        ?= us-central1
SHORTENER_DIR ?= ../url-shortener-service
REDIRECT_DIR  ?= ../url-redirect-service

export PROJECT REGION SHORTENER_DIR REDIRECT_DIR

.PHONY: help destroy restore seed-secrets build-and-deploy smoke-test verify

help:
	@echo ""
	@echo "Demo targets"
	@echo "  destroy           — state rm protected resources, then terraform destroy"
	@echo "  restore           — full restore: import + apply + seed + build + deploy + verify"
	@echo ""
	@echo "Component targets (used by restore, runnable individually)"
	@echo "  seed-secrets      — repopulate shortener-api-key and redis-auth-string"
	@echo "  build-and-deploy  — Cloud Build images, deploy services, update job"
	@echo "  smoke-test        — direct + gateway path checks with Firestore cleanup"
	@echo "  verify            — alias for smoke-test"
	@echo ""

destroy:
	bash scripts/destroy.sh

restore:
	bash scripts/restore.sh

seed-secrets:
	bash scripts/seed_secrets.sh

build-and-deploy:
	bash scripts/build_and_deploy.sh

smoke-test:
	@if [ -z "$$API_KEY" ]; then \
	  echo "API_KEY not set; fetching from Secret Manager..."; \
	  API_KEY="$$(gcloud secrets versions access latest --secret=shortener-api-key --project=$(PROJECT))" \
	    bash scripts/smoke_test.sh; \
	else \
	  bash scripts/smoke_test.sh; \
	fi

verify: smoke-test
