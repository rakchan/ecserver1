ECSVR_IMG=ecserver
TEST_IMG=service-test-suite
ifndef IMAGE_TAG
  IMAGE_TAG=latest
endif
CLUSTER_IP := $(shell ping -W2 -n -q -c1 current-cluster-roost.io  2> /dev/null | awk -F '[()]' '/PING/ { print $$2}')

# HOSTNAME := $(shell hostname)
.PHONY: all
all: dockerise helm-deploy

.PHONY: test
test: test-ecserver

.PHONY: test-ecserver
test-ecserver:
	echo "Test ECserver"
	docker run --network="host" --rm -it -v ${PWD}/ecserver/test:/scripts \
   zbio/artillery-custom \
   run -e unit /scripts/test.yaml

.PHONY: dockerise
dockerise: build-ecserver

.PHONY: build-ecserver
build-ecserver:
ifdef DOCKER_HOST
	docker -H ${DOCKER_HOST} build -t ${ECSVR_IMG}:${IMAGE_TAG} -f ecserver/Dockerfile ecserver
else
	docker build -t ${ECSVR_IMG}:${IMAGE_TAG} -f ecserver/Dockerfile ecserver
endif

.PHONY: helm-deploy
helm-deploy: 
ifeq ($(strip $(CLUSTER_IP)),)
	@echo "UNKNOWN_CLUSTER_IP: failed to resolve current-cluster-roost.io to an valid IP"
	@exit 1;
endif
		helm install vote helm-vote --set clusterIP=$(CLUSTER_IP)
		
.PHONY: helm-undeploy
helm-undeploy:
		-helm uninstall vote

.PHONY: clean
clean: helm-undeploy
