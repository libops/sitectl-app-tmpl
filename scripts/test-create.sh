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

verify_template_lock() {
	local lock="${SITE_DIR}/.libops/template.lock.yaml"
	local contract="${FIXTURE_REPO}/.libops/template-contract.yaml"
	local contract_digest
	local fixture_commit
	local lock_mode
	contract_digest="sha256:$(sha256sum "${contract}" | awk '{print $1}')"
	fixture_commit="$(git -C "${FIXTURE_REPO}" rev-parse HEAD)"

	test -f "${lock}" && test ! -L "${lock}"
	lock_mode="$(stat -c '%a' "${lock}")"
	test "${lock_mode}" = "644"
	grep -Fxq "apiVersion: sitectl.libops.io/v1alpha1" "${lock}"
	grep -Fxq "kind: TemplateLock" "${lock}"
	grep -Fxq "schema: 1" "${lock}"
	awk -v expected="${FIXTURE_REPO}" '$1 == "repository:" && $2 == expected { count++ } END { exit count != 1 }' "${lock}"
	awk -v expected="${fixture_commit}" '$1 == "commit:" && $2 == expected { count++ } END { exit count != 1 }' "${lock}"
	awk '$1 == "path:" && $2 == ".libops/template-contract.yaml" { count++ } END { exit count != 1 }' "${lock}"
	awk -v expected="${contract_digest}" '$1 == "digest:" && $2 == expected { count++ } END { exit count != 1 }' "${lock}"
	awk '$1 == "revision:" && $2 == "app-tmpl-v1" { count++ } END { exit count != 1 }' "${lock}"
	awk '
		$1 == "sitectl:" { in_sitectl = 1; next }
		in_sitectl && /^[^[:space:]]/ { in_sitectl = 0 }
		in_sitectl && $1 == "version:" && $2 == "1.0.0" { found = 1 }
		END { exit !found }
	' "${lock}"
	awk '
		$1 == "-" && $2 == "package:" && $3 == "sitectl-app-tmpl" { found = 1 }
		END { exit !found }
	' "${lock}"
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
	verify_template_lock
	compose_up
	run_healthcheck
	run_verify
}

main "$@"
