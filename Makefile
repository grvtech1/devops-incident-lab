.PHONY: test validate preflight bootstrap deploy smoke verify-alerts incidents status evidence clean

test:
	npm test

validate:
	bash scripts/validate-config.sh

preflight:
	bash scripts/preflight.sh

bootstrap:
	bash scripts/bootstrap-kind.sh

deploy:
	bash scripts/deploy.sh

smoke:
	bash scripts/smoke-test.sh

verify-alerts:
	bash scripts/verify-alert-delivery.sh

incidents:
	bash scripts/lab.sh list

status:
	bash scripts/lab.sh status

evidence:
	bash scripts/collect-evidence.sh manual

clean:
	kind delete cluster --name incident-lab
