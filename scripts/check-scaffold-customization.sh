#!/bin/sh
set -eu

official_repository="libops/sitectl-app-tmpl"
if [ "${GITHUB_REPOSITORY:-}" = "$official_repository" ]; then
  echo "Allowing the official $official_repository scaffold release."
  exit 0
fi

root_dir="${SCAFFOLD_ROOT_DIR:-$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)}"
failed=false

require_replacement() {
  file="$1"
  marker="$2"
  description="$3"

  if [ ! -f "$root_dir/$file" ]; then
    echo "release blocked: required scaffold file is missing: $file" >&2
    failed=true
    return
  fi
  if grep -Fq -- "$marker" "$root_dir/$file"; then
    echo "release blocked: replace the scaffold $description in $file" >&2
    failed=true
  fi
}

require_pattern_replacement() {
  file="$1"
  pattern="$2"
  description="$3"

  if [ ! -f "$root_dir/$file" ]; then
    echo "release blocked: required scaffold file is missing: $file" >&2
    failed=true
    return
  fi
  if grep -Eq -- "$pattern" "$root_dir/$file"; then
    echo "release blocked: replace the scaffold $description in $file" >&2
    failed=true
  fi
}

require_pattern_replacement go.mod \
  '^[[:space:]]*module[[:space:]]+github[.]com/libops/sitectl-app-tmpl[[:space:]]*$' \
  "Go module path"
require_pattern_replacement cmd/root.go \
  '^[[:space:]]*PluginName[[:space:]]*=[[:space:]]*"app-tmpl"' \
  "plugin name"
require_pattern_replacement cmd/root.go \
  '^[[:space:]]*TemplateRepo[[:space:]]*=[[:space:]]*"https://github[.]com/libops/app-tmpl"' \
  "Compose template repository"
require_pattern_replacement cmd/root.go \
  '^[[:space:]]*AppImage[[:space:]]*=[[:space:]]*"libops/app:local"' \
  "application image"
require_replacement cmd/root.go \
  "replace this fail-closed template command" \
  "migration command"
require_replacement cmd/verify.go \
  "No application-specific behavioral verification is configured." \
  "verification runner"
require_pattern_replacement Makefile \
  '^[[:space:]]*BINARY_NAME[[:space:]]*=[[:space:]]*sitectl-app-tmpl[[:space:]]*$' \
  "binary name"
require_replacement .goreleaser.yaml \
  "sitectl-app-tmpl" \
  "GoReleaser binary, package, and repository identifiers"
require_pattern_replacement .github/workflows/goreleaser.yaml \
  '^[[:space:]]*package-name:[[:space:]]*sitectl-app-tmpl[[:space:]]*$' \
  "release workflow package name"
require_pattern_replacement scripts/test-create.sh \
  '^[[:space:]]*PLUGIN_BINARY[[:space:]]*=[[:space:]]*"sitectl-app-tmpl"[[:space:]]*$' \
  "integration-test binary name"

if [ "$failed" = true ]; then
  echo "Derived releases must replace every scaffold marker before publishing." >&2
  exit 1
fi

echo "Scaffold customization guard passed."
