# sitectl-app-tmpl

Template repository for a new Docker Compose-backed `sitectl` application plugin. Use it when an app has a standalone Compose template repository and needs app-specific create and rollout metadata, helpers, validation, debug output, health checks, and behavioral verification.

The scaffold requires stable `sitectl` v1.0.0 or newer and uses RPC schema 1. Its migration placeholder fails closed, its verification runner reports that behavioral verification is unfinished, and derived repositories cannot release while the scaffold markers remain. Before releasing a derived plugin, replace those markers with the application's supported migration and behavioral checks. Keep lifecycle steps in plugin metadata; do not delegate rollout to a downstream `scripts/rollout.sh`.

Compose template repositories should publish `.libops/template-contract.yaml` and `.libops/component-defaults.revision`. On template checkout, `sitectl` validates that contract and writes `.libops/template.lock.yaml` into the downstream project with the exact template commit, contract digest, component-defaults revision, core version, and plugin versions. The source template must never contain the generated lock file.

The official `libops/sitectl-app-tmpl` package exists to validate the scaffold and release toolchain. It is not an application plugin: fork the repository and replace the module, binary, plugin, template repository, migration, and verification placeholders before use. Dev mode is disabled by default so a derived plugin cannot accidentally mount a host directory over an application bundled in its base image. Enable it only with explicitly downstream-owned mount paths.

Core lifecycle operations stay in `sitectl`:

```bash
sitectl create your-plugin/default --path ./app --type local --checkout-source template --setup-only
sitectl compose up
sitectl compose logs -f
sitectl healthcheck
sitectl verify
```

Development commands:

```bash
make work
make test
make install
```

Releases are created only from merged pull requests. Use a semantic bump marker
such as `[patch]`, `[minor]`, or `[major]` in the pull request title; use
`[skip-release]` for changes that must not publish. On a new derived repository,
the first release-bearing merge creates a `v0.0.0` baseline tag at the
trusted pre-merge commit and publishes the requested first version. The release
workflow checks out only trusted default-branch code, so this remains safe for
pull requests from forks.

GitHub release archives and native packages are enabled by default. Publishing
those packages into a Debian or RPM repository is a separate, opt-in step:
derived plugins should enable `publish-package-repo` only after wiring their own
trusted package publisher and cloud identity into the reusable workflow.

Full plugin authoring checklist and architecture notes:

https://sitectl.libops.io/contributing/app-template
