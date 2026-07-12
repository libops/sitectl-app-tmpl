#!/bin/sh
set -eu

root_dir="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
guard="$root_dir/scripts/check-scaffold-customization.sh"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/sitectl-app-tmpl-guard.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

mkdir -p "$tmp/cmd" "$tmp/.github/workflows" "$tmp/scripts"
cat >"$tmp/go.mod" <<'EOF'
module example.com/derived/sitectl-catalog
EOF
cat >"$tmp/cmd/root.go" <<'EOF'
const (
  PluginName = "catalog"
  TemplateRepo = "https://github.com/example/catalog"
  AppImage = "ghcr.io/example/catalog:1.0.0"
)
var migration = "catalog migrate"
EOF
cat >"$tmp/cmd/verify.go" <<'EOF'
package cmd
var verify = "catalog smoke"
EOF
cat >"$tmp/Makefile" <<'EOF'
BINARY_NAME=sitectl-catalog
EOF
cat >"$tmp/.goreleaser.yaml" <<'EOF'
builds:
  - binary: sitectl-catalog
EOF
cat >"$tmp/.github/workflows/goreleaser.yaml" <<'EOF'
with:
  package-name: sitectl-catalog
EOF
cat >"$tmp/scripts/test-create.sh" <<'EOF'
PLUGIN_BINARY="sitectl-catalog"
EOF

run_guard() {
  GITHUB_REPOSITORY=example/sitectl-catalog SCAFFOLD_ROOT_DIR="$tmp" "$guard"
}

run_guard >/dev/null
GITHUB_REPOSITORY=libops/sitectl-app-tmpl SCAFFOLD_ROOT_DIR=/nonexistent "$guard" >/dev/null

expect_blocked() {
  file="$1"
  marker="$2"
  backup="$tmp/.guard-backup"

  cp "$tmp/$file" "$backup"
  printf '%s\n' "$marker" >>"$tmp/$file"
  if run_guard >/dev/null 2>&1; then
    echo "customization guard accepted scaffold marker in $file: $marker" >&2
    exit 1
  fi
  mv "$backup" "$tmp/$file"
}

expect_blocked go.mod 'module github.com/libops/sitectl-app-tmpl'
expect_blocked cmd/root.go 'PluginName = "app-tmpl"'
expect_blocked cmd/root.go 'TemplateRepo = "https://github.com/libops/app-tmpl"'
expect_blocked cmd/root.go 'AppImage = "libops/app:local"'
expect_blocked cmd/root.go 'replace this fail-closed template command'
expect_blocked cmd/verify.go 'No application-specific behavioral verification is configured.'
expect_blocked Makefile 'BINARY_NAME=sitectl-app-tmpl'
expect_blocked .goreleaser.yaml 'binary: sitectl-app-tmpl'
expect_blocked .github/workflows/goreleaser.yaml 'package-name: sitectl-app-tmpl'
expect_blocked scripts/test-create.sh 'PLUGIN_BINARY="sitectl-app-tmpl"'

mv "$tmp/Makefile" "$tmp/Makefile.removed"
if run_guard >/dev/null 2>&1; then
  echo "customization guard accepted a derived release with a required file missing" >&2
  exit 1
fi

echo "Scaffold customization guard tests passed."
