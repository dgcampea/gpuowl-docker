override IMAGE_NAME="gpuowl"
EXTRA_PROGRAMS = gpuowl-wrapper.sh

LATEST ?= 1
ROCM_VER = latest
CHECKOUT = HEAD

.PHONY: image install doc push
.DEFAULT_GOAL := image

BUILD_ARG = -c $(CHECKOUT) -r $(ROCM_VER)
ifeq ($(LATEST),1)
	BUILD_ARG += -l
endif

SRCDIR = src
SRCDOCDIR = $(SRCDIR)/doc

image:
	buildah unshare $(SRCDIR)/build-image.sh $(BUILD_ARG)

install:
	install -m755 -t "$(HOME)"/.local/bin extras/$(EXTRA_PROGRAMS)

doc:
	pandoc --toc -V toc-title:"Table of Contents" --template $(SRCDOCDIR)/template.markdown -f markdown+yaml_metadata_block -t gfm -o README.md $(SRCDOCDIR)/README.md.in
	pandoc --toc -V toc-title:"Table of Contents" --template $(SRCDOCDIR)/template.markdown -f markdown+yaml_metadata_block -t gfm -o CONTRIB.md $(SRCDOCDIR)/CONTRIB.md.in

push:
ifeq ($(LATEST),1)
	@echo $(CR_PAT) | podman login ghcr.io -u $(GH_USER) --password-stdin
	podman push $(IMAGE_NAME):latest ghcr.io/$(GH_USER)/$(GH_PKG):latest
	sleep 5
	podman push $(IMAGE_NAME):latest ghcr.io/$(GH_USER)/$(GH_PKG):$(shell podman inspect --type image gpuowl:latest  | jq '.[0].Annotations."org.opencontainers.image.version"')
	podman logout ghcr.io
endif
