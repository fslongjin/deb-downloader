DOCKER_TAG ?= ubuntu2204
PACKAGE_NAME ?=

.PHONY: all
all:
	echo ""


.PHONY: build-docker-ubuntu2204
build-docker-ubuntu2204:
	docker build -t deb-downloader:ubuntu2204 -f ./docker/Dockerfile.ubuntu2204 ./docker

.PHONY: run
run:
	docker run --rm -it -v $(shell pwd):/app deb-downloader:$(DOCKER_TAG) bash

.PHONY: download
download:
	docker run --rm -it -v $(shell pwd):/app deb-downloader:$(DOCKER_TAG) python3 main.py download $(PACKAGE_NAME)

.PHONY: unpack
unpack:
	docker run --rm -it -v $(shell pwd):/app deb-downloader:$(DOCKER_TAG) python3 main.py unpack

.PHONY: clean
clean:
	rm -rf ./output