#!/usr/bin/env bash

set -euo pipefail
set -x

export TERM="${TERM:-dumb}"

PLUGIN_NAME="app-tmpl"
PLUGIN_BINARY="sitectl-app-tmpl"
SITE_DIR_NAME="app"
CREATE_DEFINITION="${CREATE_DEFINITION:-default}"
CREATE_ARGS="${CREATE_ARGS:-}"
SITECTL_CONTEXT="${SITECTL_CONTEXT:-integration-test}"

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)"

if [ -n "${SITECTL_TMP_PARENT:-}" ]; then
	TMP_PARENT="${SITECTL_TMP_PARENT}"
elif [ -n "${GITHUB_WORKSPACE:-}" ]; then
	TMP_PARENT="${GITHUB_WORKSPACE}"
else
	TMP_PARENT="${HOME}/.tmp"
fi
mkdir -p "${TMP_PARENT}"
TMP_DIR="$(mktemp -d "${TMP_PARENT%/}/${PLUGIN_BINARY}-test.XXXXXX")"
SITECTL_HOME="${TMP_DIR}/home"
BIN_DIR="${TMP_DIR}/bin"
SITE_DIR="${TMP_DIR}/${SITE_DIR_NAME}"
FIXTURE_REPO="${TMP_DIR}/compose-template"
PATH="${BIN_DIR}:${PATH}"
export PATH
mkdir -p "${SITECTL_HOME}"

remove_tmp_dir() {
	if [ ! -d "${TMP_DIR}" ]; then
		return
	fi
	chmod -R u+rwX "${TMP_DIR}" 2>/dev/null || true
	if rm -rf "${TMP_DIR}" 2>/dev/null; then
		return
	fi
	if command -v sudo >/dev/null 2>&1; then
		sudo chown -R "$(id -u):$(id -g)" "${TMP_DIR}" 2>/dev/null || true
		sudo chmod -R u+rwX "${TMP_DIR}" 2>/dev/null || true
	fi
	rm -rf "${TMP_DIR}"
}

cleanup() {
	if [ -d "${SITE_DIR}" ] && command -v sitectl >/dev/null 2>&1; then
		HOME="${SITECTL_HOME}" sitectl compose down -v --remove-orphans >/dev/null 2>&1 || true
	fi
	remove_tmp_dir
}
trap cleanup EXIT

build_plugin() {
	mkdir -p "${BIN_DIR}"
	(
		cd "${REPO_ROOT}" &&
			go build -o "${BIN_DIR}/${PLUGIN_BINARY}" .
	)
	command -v sitectl >/dev/null
	command -v "${PLUGIN_BINARY}" >/dev/null
}

prepare_fixture() {
	mkdir -p "${FIXTURE_REPO}"
	cp -a "${REPO_ROOT}/testdata/compose-template/." "${FIXTURE_REPO}/"
	git -C "${FIXTURE_REPO}" init -q -b main
	git -C "${FIXTURE_REPO}" config user.email "actions@github.com"
	git -C "${FIXTURE_REPO}" config user.name "GitHub Actions"
	git -C "${FIXTURE_REPO}" add .
	git -C "${FIXTURE_REPO}" commit -q -m "Create integration fixture"
	(
		cd "${FIXTURE_REPO}" &&
			docker compose config --quiet
	)
}

create_site() {
	local target="${PLUGIN_NAME}/${CREATE_DEFINITION}"
	local extra_args=()
	if [ -n "${CREATE_ARGS}" ]; then
		read -r -a extra_args <<< "${CREATE_ARGS}"
	fi

	HOME="${SITECTL_HOME}" sitectl create "${target}" \
		--path "${SITE_DIR}" \
		--type local \
		--context "${SITECTL_CONTEXT}" \
		--checkout-source template \
		--template-repo "${FIXTURE_REPO}" \
		--default-context \
		--setup-only \
		"${extra_args[@]}"
}

compose_up() {
	if ! HOME="${SITECTL_HOME}" sitectl compose up; then
		(
			cd "${SITE_DIR}" &&
				docker compose ps -a &&
				docker compose logs --no-color || true
		)
		exit 1
	fi
}

run_healthcheck() {
	HOME="${SITECTL_HOME}" sitectl healthcheck
}

run_verify() {
	HOME="${SITECTL_HOME}" sitectl verify
}

main() {
	build_plugin
	prepare_fixture
	create_site
	compose_up
	run_healthcheck
	run_verify
}

main "$@"
