# Shortcut targets
default: image

## Build binary for current platform
all: image

# BUILDARCH is the host architecture
# ARCH is the target architecture
# we need to keep track of them separately
BUILDARCH ?= $(shell uname -m)

# canonicalized names for host architecture
ifeq ($(BUILDARCH),aarch64)
        BUILDARCH=arm64
endif
ifeq ($(BUILDARCH),x86_64)
        BUILDARCH=amd64
endif
ifeq ($(BUILDARCH),armv7l)
        BUILDARCH=armv7
endif

###############################################################################
VERSION ?= v5.17
DEFAULTORG ?= library
DEFAULTIMAGE ?= $(DEFAULTORG)/bpftool:$(VERSION)
BPFTOOLIMAGE ?= $(DEFAULTIMAGE)-$(BUILDARCH)
KERNELREF ?= $(VERSION)
KERNELREPO ?= git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git

###############################################################################
# Building the image
###############################################################################
image: $(DEFAULTORG)/bpftool
$(DEFAULTORG)/bpftool:
	docker build --build-arg KERNEL_REF=$(KERNELREF) --build-arg KERNEL_REPO=$(KERNELREPO) --cpuset-cpus 0 --pull -t $(BPFTOOLIMAGE) .

###############################################################################
# UTs
###############################################################################
test:
	docker run --rm $(BPFTOOLIMAGE) /bpftool version | grep -q "bpftool v"
	@echo "success"
