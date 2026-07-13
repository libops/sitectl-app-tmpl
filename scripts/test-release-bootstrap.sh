#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
release_workflow="$repo_root/.github/workflows/github-release.yaml"
goreleaser_workflow="$repo_root/.github/workflows/goreleaser.yaml"

fail() {
  echo "release bootstrap contract: $*" >&2
  exit 1
}

require_line() {
  local file="$1" expected="$2" message="$3"
  grep -Fq -- "$expected" "$file" || fail "$message"
}

require_line "$release_workflow" 'group: release' \
  "release creation is not serialized"
require_line "$release_workflow" 'ref: ${{ github.event.pull_request.merge_commit_sha }}' \
  "initial-version seeding does not inspect the trusted merged revision"
require_line "$release_workflow" "grep -Eq '^v[0-9]+\\.[0-9]+\\.[0-9]+$'" \
  "initial-version seeding does not recognize stable version tags"
require_line "$release_workflow" 'baseline="$(git rev-parse HEAD^)"' \
  "the initial baseline would hide the first merged release change"
require_line "$release_workflow" 'git push origin refs/tags/v0.0.0' \
  "the initial semantic-version baseline is not published"
require_line "$release_workflow" 'needs: seed-initial-version' \
  "release creation can race the initial-version baseline"
require_line "$goreleaser_workflow" "if: github.ref_name != 'v0.0.0'" \
  "the seed tag would publish a placeholder plugin release"

echo "Release bootstrap contracts passed."
