.PHONY: build check-core-version deps deps-update lint mod-check test work install integration-test

BINARY_NAME=sitectl-app-tmpl
GO ?= go
GOFMT ?= gofmt
CREATE_DEFINITION?=default
CREATE_ARGS?=
SITECTL_CONTEXT?=integration-test

deps:
	$(GO) mod download

deps-update:
	$(GO) get -u ./...
	$(GO) mod tidy

build: deps
	$(GO) build -o $(BINARY_NAME) .

install: build
	mv $(BINARY_NAME) /usr/local/bin

lint:
	test -z "$$(find . -name '*.go' -not -path './vendor/*' -exec $(GOFMT) -l {} +)"
	golangci-lint run

check-core-version:
	./scripts/check-sitectl-core-version.sh v1.9.0

mod-check:
	$(GO) mod tidy -diff

test: check-core-version deps
	./scripts/test-scaffold-customization.sh
	./scripts/test-release-bootstrap.sh
	$(GO) test ./...

work:
	./scripts/use-go-work.sh

integration-test:
	SITECTL_CONTEXT="$(SITECTL_CONTEXT)" CREATE_DEFINITION="$(CREATE_DEFINITION)" CREATE_ARGS="$(CREATE_ARGS)" ./scripts/test-create.sh
