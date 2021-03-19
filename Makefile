override IMAGE_NAME="gpuowl"
EXTRA_PROGRAMS = gpuowl-wrapper.sh

EXTRA_PODMAN_FLAGS =

LATEST ?= $(if ($(origin COMMIT), undefined),yes,no)
COMMIT ?= $(shell git ls-remote https://github.com/preda/gpuowl.git HEAD | cut -f1)
ifeq ($(strip $(COMMIT)),)
	COMMIT = HEAD
endif

.PHONY: image image-nocache extract-version tag build install doc push
.DEFAULT_GOAL := image


image-nocache: EXTRA_PODMAN_ARGS += "--no-cache"
image-nocache: image

image: extract-version

install:
ifneq ($(EXTRA_PROGRAMS),)
	install -m755 -t "$(HOME)"/.local/bin $(EXTRA_PROGRAMS)
endif

doc:
	pandoc --toc -V toc-title:"Table of Contents" --template doc/template.markdown -f markdown+yaml_metadata_block -t gfm -o README.md doc/README.md.in

push: LIST = latest $(COMMIT) $(shell podman run --rm --tmpfs /in --entrypoint cat $(IMAGE_NAME):latest /app/version | tr -d \")
push: image
ifeq ($(LATEST),yes)
	echo $(CR_PAT) | podman login ghcr.io -u $(GH_USER) --password-stdin
	for i in $(LIST); do \
		podman push $(IMAGE_NAME):latest ghcr.io/$(GH_USER)/$(GH_PKG):$$i; \
	done
	podman logout ghcr.io
endif

##############################

# hack:
# 1. temp. tag the building stage from dockerfile and extract the gpuowl tag
# 2. make tag -> build
# 3. untag temp.
extract-version:
	podman build $(EXTRA_PODMAN_FLAGS) -f Dockerfile --target builder \
		 --build-arg COMMIT=$(COMMIT) \
		 --tag $(IMAGE_NAME):ext_ver
	$(MAKE) tag IMG_VER=$$(podman run --rm --entrypoint cat $(IMAGE_NAME):ext_ver version.inc | tr -d \" )
	podman untag $(IMAGE_NAME):ext_ver

tag: build
ifeq ($(LATEST),yes)
	podman tag $(IMAGE_NAME):$(COMMIT) $(IMAGE_NAME):latest
endif
	podman tag $(IMAGE_NAME):$(COMMIT) $(IMAGE_NAME):$(IMG_VER)

build:
	podman build $(EXTRA_PODMAN_FLAGS) -f Dockerfile --target application \
	  --build-arg COMMIT=$(COMMIT) \
	  --annotation=org.opencontainers.image.licenses=GPL-3.0 \
	  --annotation=org.opencontainers.image.version=$(IMG_VER) \
	  --annotation=org.opencontainers.image.revision=git \
	  --tag $(IMAGE_NAME):$(COMMIT)
