# Publishing netdata on Horizon: 

SERVICE_NAME:="netdata"
SERVICE_VERSION:="1.0.0"

# Get the Open-Horizon architecture type and IP address for this host
ARCH:=$(shell ./helper -a)
HOST_IP:=$(shell ./helper -i)

#
# Targets for building, developing, testing and cleaning this service
#

build: validate-dockerhubid
	docker build -t $(DOCKERHUB_ID)/$(SERVICE_NAME)_$(ARCH):$(SERVICE_VERSION) -f ./Dockerfile.$(ARCH) .

push: validate-dockerhubid
	docker push $(DOCKERHUB_ID)/$(SERVICE_NAME)_$(ARCH):$(SERVICE_VERSION) 

dev: build validate-dockerhubid
	-docker rm -f ${SERVICE_NAME} 2>/dev/null || :
	docker run -it -v `pwd`:/outside \
          -p 19999:19999 \
          -v /etc/passwd:/host/etc/passwd:ro \
          -v /etc/group:/host/etc/group:ro \
          -v /proc:/host/proc:ro \
          -v /sys:/host/sys:ro \
          -v /etc/os-release:/host/etc/os-release:ro \
          --cap-add SYS_PTRACE \
          --security-opt apparmor=unconfined \
	  --name ${SERVICE_NAME} \
	  $(DOCKERHUB_ID)/$(SERVICE_NAME)_$(ARCH):$(SERVICE_VERSION) /bin/sh

run: validate-dockerhubid
	-docker rm -f ${SERVICE_NAME} 2>/dev/null || :
	docker run --rm -d \
          -p 19999:19999 \
          -v /etc/passwd:/host/etc/passwd:ro \
          -v /etc/group:/host/etc/group:ro \
          -v /proc:/host/proc:ro \
          -v /sys:/host/sys:ro \
          -v /etc/os-release:/host/etc/os-release:ro \
          --cap-add SYS_PTRACE \
          --security-opt apparmor=unconfined \
	  --name ${SERVICE_NAME} \
	  $(DOCKERHUB_ID)/$(SERVICE_NAME)_$(ARCH):$(SERVICE_VERSION)
	@echo "The netdata visualization is available at: \"http://$(HOST_IP):19999/\"."

clean: validate-dockerhubid
	@docker rm -f ${SERVICE_NAME} 2>/dev/null || :
	@docker rmi $(DOCKERHUB_ID)/$(SERVICE_NAME)_$(ARCH):$(SERVICE_VERSION) 2>/dev/null || :

#
# Targets for publishing this service to an Open-Horizon Exhange
#
# NOTE: You must install the Open-Horizon CLI in order to use these targets!
#

publish-service: validate-dockerhubid
	ARCH=$(ARCH) \
          SERVICE_NAME="$(SERVICE_NAME)" \
          SERVICE_VERSION="$(SERVICE_VERSION)"\
          DOCKER_IMAGE_BASE="$(DOCKERHUB_ID)/$(SERVICE_NAME)"\
          hzn exchange service publish -O -f service.json --pull-image

publish-all-services: validate-dockerhubid
	docker build -t $(DOCKERHUB_ID)/$(SERVICE_NAME)_arm:$(SERVICE_VERSION) -f ./Dockerfile.arm .
	docker push $(DOCKERHUB_ID)/$(SERVICE_NAME)_arm:$(SERVICE_VERSION) 
	ARCH=arm \
          SERVICE_NAME="$(SERVICE_NAME)" \
          SERVICE_VERSION="$(SERVICE_VERSION)"\
          DOCKER_IMAGE_BASE="$(DOCKERHUB_ID)/$(SERVICE_NAME)"\
          hzn exchange service publish -O -f service.json --pull-image
	docker build -t $(DOCKERHUB_ID)/$(SERVICE_NAME)_arm64:$(SERVICE_VERSION) -f ./Dockerfile.arm64 .
	docker push $(DOCKERHUB_ID)/$(SERVICE_NAME)_arm64:$(SERVICE_VERSION) 
	ARCH=arm64 \
          SERVICE_NAME="$(SERVICE_NAME)" \
          SERVICE_VERSION="$(SERVICE_VERSION)"\
          DOCKER_IMAGE_BASE="$(DOCKERHUB_ID)/$(SERVICE_NAME)"\
          hzn exchange service publish -O -f service.json --pull-image
	docker build -t $(DOCKERHUB_ID)/$(SERVICE_NAME)_amd64:$(SERVICE_VERSION) -f ./Dockerfile.amd64 .
	docker push $(DOCKERHUB_ID)/$(SERVICE_NAME)_amd64:$(SERVICE_VERSION) 
	ARCH=amd64 \
          SERVICE_NAME="$(SERVICE_NAME)" \
          SERVICE_VERSION="$(SERVICE_VERSION)"\
          DOCKER_IMAGE_BASE="$(DOCKERHUB_ID)/$(SERVICE_NAME)"\
          hzn exchange service publish -O -f service.json --pull-image

#
# Sanity check targets
#

validate-dockerhubid:
	@if [ -z "${DOCKERHUB_ID}" ]; \
          then { echo "***** ERROR: \"DOCKERHUB_ID\" is not set!"; exit 1; }; \
          else echo "  NOTE: Using DockerHubID: \"${DOCKERHUB_ID}\""; \
        fi
	@sleep 1

.PHONY: build dev test clean publish-service publish-all-services validate-dockerhubid

