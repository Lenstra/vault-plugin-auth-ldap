# Metadata about this makefile and position
MKFILE_PATH := $(lastword $(MAKEFILE_LIST))
CURRENT_DIR := $(patsubst %/,%,$(dir $(realpath $(MKFILE_PATH))))

PROJECT := $(CURRENT_DIR:$(GOPATH)/src/%=%)
OWNER := $(notdir $(patsubst %/,%,$(dir $(PROJECT))))
NAME := $(notdir $(PROJECT))
VERSION := 1.9.7

GOARCH = amd64

UNAME = $(shell uname -s)

# Default os-arch combination to build
XC_OS ?= darwin freebsd linux netbsd openbsd solaris windows
XC_ARCH ?= 386 amd64 arm
XC_EXCLUDE ?= darwin/386 darwin/arm solaris/386 solaris/arm windows/arm

ifndef OS
	ifeq ($(UNAME), Linux)
		OS = linux
	else ifeq ($(UNAME), Darwin)
		OS = darwin
	endif
endif

.DEFAULT_GOAL := all

all: fmt build start

start:
	vault server -dev -dev-root-token-id=root -dev-plugin-dir=./vault/plugins

enable:
	vault auth enable -path=mock-auth vault-plugin-auth-ldap

clean:
	rm -f ./vault/plugins/vault-plugin-auth-ldap

test:
	go test ./...

fmt:
	go fmt $$(go list ./...)

# Create a cross-compile target for every os-arch pairing. This will generate
# a make target for each os/arch like "make linux/amd64" as well as generate a
# meta target (build) for compiling everything.
define make-xc-target
  $1/$2:
  ifneq (,$(findstring ${1}/${2},$(XC_EXCLUDE)))
		@printf "%s%20s %s\n" "-->" "${1}/${2}:" "${PROJECT} (excluded)"
  else
		@printf "%s%20s %s\n" "-->" "${1}/${2}:" "${PROJECT}"
		@CGO_ENABLED="0" GOOS="${1}" GOARCH="${2}" \
				go build -a \
					-o="pkg/${1}_${2}/${NAME}-${VERSION}${3}"
  endif
  .PHONY: $1/$2

  $1:: $1/$2
  .PHONY: $1

  build:: $1/$2
  .PHONY: build
endef
$(foreach goarch,$(XC_ARCH),$(foreach goos,$(XC_OS),$(eval $(call make-xc-target,$(goos),$(goarch),$(if $(findstring windows,$(goos)),.exe,)))))

# _cleanup removes any previous binaries
_cleanup:
	@rm -rf "${CURRENT_DIR}/pkg/"
	@rm -rf "${CURRENT_DIR}/bin/"


# _compress compresses all the binaries in pkg/* as tarball and zip.
_compress:
	@mkdir -p "${CURRENT_DIR}/pkg/dist"
	@for platform in $$(find ./pkg -mindepth 1 -maxdepth 1 -type d); do \
		osarch=$$(basename "$$platform"); \
		if [ "$$osarch" = "dist" ]; then \
			continue; \
		fi; \
		\
		ext=""; \
		if test -z "$${osarch##*windows*}"; then \
			ext=".exe"; \
		fi; \
		cd "$$platform"; \
		tar -czf "${CURRENT_DIR}/pkg/dist/${NAME}_${VERSION}_$${osarch}.tgz" "${NAME}-${VERSION}$${ext}"; \
		zip -q "${CURRENT_DIR}/pkg/dist/${NAME}_${VERSION}_$${osarch}.zip" "${NAME}-${VERSION}$${ext}"; \
		cd - &>/dev/null; \
	done

# dist builds the binaries and then signs and packages them for distribution
dist:
	@$(MAKE) -f "${MKFILE_PATH}" _cleanup
	@$(MAKE) -f "${MKFILE_PATH}" -j4 build
	@$(MAKE) -f "${MKFILE_PATH}" _compress _checksum

# _checksum produces the checksums for the binaries in pkg/dist
_checksum:
	@cd "${CURRENT_DIR}/pkg/dist" && \
		shasum --algorithm 256 * > ${CURRENT_DIR}/pkg/dist/${NAME}_${VERSION}_SHA256SUMS && \
		cd - &>/dev/null


.PHONY: build clean fmt start enable _cleanup _compress _checksum dist
