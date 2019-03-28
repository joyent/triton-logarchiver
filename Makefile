#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

#
# Copyright 2019, Joyent, Inc.
#

#
# LogArchiver Makefile
#

NAME		:=logarchiver

#
# Configuration used by Makefile.defs and Makefile.targ to generate
# "check" and "docs" targets.
#
JSON_FILES	= package.json

#
# Makefile.defs defines variables used as part of the build process.
#

ifeq ($(shell uname -s),SunOS)
	NODE_PREBUILT_VERSION =	v6.15.1
	NODE_PREBUILT_IMAGE=18b094b0-eb01-11e5-80c1-175dac7ddf02
	NODE_PREBUILT_TAG := zone
else
	NPM=npm
	NODE=node
	NPM_EXEC=$(shell which npm)
	NODE_EXEC=$(shell which node)
endif

ENGBLD_USE_BUILDIMAGE	= true
ENGBLD_REQUIRE		:= $(shell git submodule update --init deps/eng)
include ./deps/eng/tools/mk/Makefile.defs
TOP ?= $(error Unable to access eng.git submodule Makefiles.)

ifeq ($(shell uname -s),SunOS)
	include ./deps/eng/tools/mk/Makefile.node_prebuilt.defs
	include ./deps/eng/tools/mk/Makefile.agent_prebuilt.defs
endif
include ./deps/eng/tools/mk/Makefile.smf.defs
include ./deps/eng/tools/mk/Makefile.node_modules.defs

ROOT		:= $(shell pwd)
RELEASE_TARBALL	:= $(NAME)-pkg-$(STAMP).tar.gz
RELSTAGEDIR	:= /tmp/$(NAME)-$(STAMP)

# triton-origin-multiarch-18.1.0
BASE_IMAGE_UUID = 04a48d7d-6bb5-4e83-8c3b-e60a99e0f48f
BUILDIMAGE_NAME = $(NAME)
BUILDIMAGE_DESC = Triton LogArchiver
AGENTS		= config registrar

PATH		:= $(NODE_INSTALL)/bin:/opt/local/bin:${PATH}

#
# Repo-specific targets
#
.PHONY: all
all: $(STAMP_NODE_PREBUILT) $(STAMP_NODE_MODULES) $(NPM_EXEC) sdc-scripts

CLEAN_FILES += ./node_modules/tape

#
# Packaging targets
#

.PHONY: hermes
hermes:
	git submodule update --init deps/hermes
	cd deps/hermes && make install DESTDIR=$(TOP)/build/hermes

.PHONY: release
release: all hermes
	@echo "Building $(RELEASE_TARBALL)"
	@mkdir -p $(RELSTAGEDIR)/root/opt/triton/$(NAME)
	@mkdir -p $(RELSTAGEDIR)/site
	@touch $(RELSTAGEDIR)/site/.do-not-delete-me
	cp -r $(ROOT)/node_modules \
		$(ROOT)/package.json \
		$(ROOT)/build \
		$(RELSTAGEDIR)/root/opt/triton/$(NAME)/
	mkdir -p $(RELSTAGEDIR)/root/opt/triton/boot
	cp -R $(ROOT)/deps/sdc-scripts/* $(RELSTAGEDIR)/root/opt/triton/boot
	cp -R $(ROOT)/boot/* $(RELSTAGEDIR)/root/opt/triton/boot
	cp -r $(TOP)/build/hermes/opt/triton/hermes \
		$(RELSTAGEDIR)/root/opt/triton/hermes
	mkdir -p $(RELSTAGEDIR)/root/opt/triton/hermes/etc
	cp $(TOP)/etc/logsets.json \
		$(RELSTAGEDIR)/root/opt/triton/hermes/etc
	(cd $(RELSTAGEDIR) && $(TAR) -I pigz -cf $(ROOT)/$(RELEASE_TARBALL) root site)
	@rm -rf $(RELSTAGEDIR)

.PHONY: publish
publish: release
	@if [[ -z "$(ENGBLD_BITS_DIR)" ]]; then \
	  echo "error: 'ENGBLD_BITS_DIR' must be set for 'publish' target"; \
	  exit 1; \
	fi
	mkdir -p $(ENGBLD_BITS_DIR)/$(NAME)
	cp $(ROOT)/$(RELEASE_TARBALL) $(ENGBLD_BITS_DIR)/$(NAME)/$(RELEASE_TARBALL)

#
# Target definitions.  This is where we include the target Makefiles for
# the "defs" Makefiles we included above.
#

include ./deps/eng/tools/mk/Makefile.deps

ifeq ($(shell uname -s),SunOS)
	include ./deps/eng/tools/mk/Makefile.node_prebuilt.targ
	include ./deps/eng/tools/mk/Makefile.agent_prebuilt.targ
endif
include ./deps/eng/tools/mk/Makefile.smf.targ
include ./deps/eng/tools/mk/Makefile.targ
include ./deps/eng/tools/mk/Makefile.node_modules.targ

sdc-scripts: deps/sdc-scripts/.git
