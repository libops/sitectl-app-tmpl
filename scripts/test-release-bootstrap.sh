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
require_line "$release_workflow" 'queue: max' \
  "pending releases can be silently replaced"
if grep -Fq -- 'ref: ${{ github.event.pull_request.merge_commit_sha }}' "$release_workflow"; then
  fail "privileged checkout cannot safely use a fork pull request merge revision"
fi
require_line "$release_workflow" "grep -Eq '^v[0-9]+\\.[0-9]+\\.[0-9]+$'" \
  "initial-version seeding does not recognize stable version tags"
require_line "$release_workflow" 'BASE_SHA: ${{ github.event.pull_request.base.sha }}' \
  "the initial baseline does not use the trusted pre-merge base revision"
require_line "$release_workflow" '[[ ! "$BASE_SHA" =~ ^[0-9a-f]{40}$ ]]' \
  "the initial baseline does not validate the event commit identifier"
require_line "$release_workflow" 'git merge-base --is-ancestor "$BASE_SHA" HEAD' \
  "the initial baseline is not required to precede the merged revision"
require_line "$release_workflow" 'git tag v0.0.0 "$BASE_SHA"' \
  "the initial baseline can omit commits under a supported merge policy"
require_line "$release_workflow" 'git push origin refs/tags/v0.0.0' \
  "the initial semantic-version baseline is not published"
require_line "$release_workflow" 'needs: seed-initial-version' \
  "release creation can race the initial-version baseline"
require_line "$goreleaser_workflow" "if: github.ref_name != 'v0.0.0'" \
  "the seed tag would publish a placeholder plugin release"
require_line "$goreleaser_workflow" 'publish-package-repo: false' \
  "derived plugins would require private LibOps package infrastructure"
require_line "$repo_root/.goreleaser.yaml" 'token: "{{ .Env.HOMEBREW_REPO_TOKEN }}"' \
  "Homebrew publication is not isolated from source-release credentials"

echo "Release bootstrap contracts passed."
