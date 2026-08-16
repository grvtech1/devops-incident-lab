.PHONY: test preflight bootstrap deploy smoke incidents status evidence clean

test:
	npm test

preflight:
	bash scripts/preflight.sh

bootstrap:
	bash scripts/bootstrap-kind.sh

deploy:
	bash scripts/deploy.sh

smoke:
	bash scripts/smoke-test.sh

incidents:
	bash scripts/lab.sh list

status:
	bash scripts/lab.sh status

evidence:
	bash scripts/collect-evidence.sh manual

clean:
	kind delete cluster --name incident-lab
