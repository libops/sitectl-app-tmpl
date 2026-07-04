.PHONY: build deps lint test work install integration-test

BINARY_NAME=sitectl-app-tmpl
GO ?= go
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
	$(GO) fmt ./...
	golangci-lint run

test: build
	$(GO) test ./...

work:
	./scripts/use-go-work.sh

integration-test:
	SITECTL_CONTEXT="$(SITECTL_CONTEXT)" CREATE_DEFINITION="$(CREATE_DEFINITION)" CREATE_ARGS="$(CREATE_ARGS)" ./scripts/test-create.sh
