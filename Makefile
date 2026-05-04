destroy:
	terraform -chdir=. destroy -auto-approve

restore:
	bash scripts/redeploy_services.sh

wait:
	sleep 30

smoke-test:
	bash scripts/smoke_test.sh