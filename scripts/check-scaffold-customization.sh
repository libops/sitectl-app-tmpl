#!/bin/sh
set -eu

official_repository="libops/sitectl-app-tmpl"
if [ "${GITHUB_REPOSITORY:-}" = "$official_repository" ]; then
  echo "Allowing the official $official_repository scaffold release."
  exit 0
fi

root_dir="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
failed=false

require_replacement() {
  file="$1"
  marker="$2"
  description="$3"

  if grep -Fq -- "$marker" "$root_dir/$file"; then
    echo "release blocked: replace the scaffold $description in $file" >&2
    failed=true
  fi
}

require_pattern_replacement() {
  file="$1"
  pattern="$2"
  description="$3"

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
require_replacement cmd/root.go \
  "replace this fail-closed template command" \
  "migration command"
require_replacement cmd/verify.go \
  "No application-specific behavioral verification is configured." \
  "verification runner"
require_replacement .goreleaser.yaml \
  "package_name: sitectl-app-tmpl" \
  "package name"

if [ "$failed" = true ]; then
  echo "Derived releases must replace every scaffold marker before publishing." >&2
  exit 1
fi

echo "Scaffold customization guard passed."
