override IMAGE_NAME="gpuowl"
#EXTRA_PROGRAMS = gpuowl-wrapper.sh

ifdef COMMIT
	LATEST=no
else
	LATEST=yes
	COMMIT=$(shell git ls-remote https://github.com/preda/gpuowl.git HEAD | awk '{ print $$1 }')
	ifeq ($(COMMIT),)
		COMMIT = HEAD
	endif
endif

.PHONY: image doc push

image:
	podman build -f Dockerfile --target application --tag $(IMAGE_NAME):$(COMMIT) \
	  --build-arg COMMIT=$(COMMIT)
ifeq ($(LATEST),yes)
	podman tag $(IMAGE_NAME):$(COMMIT) $(IMAGE_NAME):latest
endif
ifneq ($(EXTRA_PROGRAMS),)
	install -m755 -t "$(HOME)"/.local/bin $(EXTRA_PROGRAMS)
endif

doc:
	pandoc --toc -V toc-title:"Table of Contents" --template doc/template.markdown -f markdown+yaml_metadata_block -t gfm -o README.md doc/README.md.in

push: image
ifeq ($(LATEST),yes)
	echo $(CR_PAT) | podman login ghcr.io -u $(GH_USER) --password-stdin
	podman tag $(IMAGE_NAME):latest ghcr.io/$(GH_USER)/$(GH_PKG):latest
	podman push ghcr.io/$(GH_USER)/$(GH_PKG):latest
	podman logout ghcr.io
endif
