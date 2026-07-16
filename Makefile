.PHONY: build check-core-version deps lint test work install integration-test

BINARY_NAME=sitectl-app-tmpl
GO ?= go
GOFMT ?= gofmt
CREATE_DEFINITION?=default
CREATE_ARGS?=
SITECTL_CONTEXT?=integration-test

deps: work
	$(GO) mod tidy

build:
	$(GO) build -o $(BINARY_NAME) .

install: build
	mv $(BINARY_NAME) /usr/local/bin

lint:
	test -z "$$(find . -name '*.go' -not -path './vendor/*' -exec $(GOFMT) -l {} +)"
	golangci-lint run

check-core-version:
	./scripts/check-sitectl-core-version.sh v1.0.0

test: check-core-version build
	./scripts/test-scaffold-customization.sh
	./scripts/test-release-bootstrap.sh
	$(GO) test ./...

work:
	./scripts/use-go-work.sh

integration-test:
	SITECTL_CONTEXT="$(SITECTL_CONTEXT)" CREATE_DEFINITION="$(CREATE_DEFINITION)" CREATE_ARGS="$(CREATE_ARGS)" ./scripts/test-create.sh
