# sitectl-app-tmpl

Template repository for a new Docker Compose-backed `sitectl` application plugin. Use it when an app has a standalone Compose template repository and needs app-specific create and rollout metadata, helpers, validation, debug output, health checks, and behavioral verification.

The scaffold requires stable `sitectl` v1.8.2 or newer and uses RPC schema 1. Its versioned template ref and migration implementation are release-blocking placeholders, its verification runner reports that behavioral verification is unfinished, and derived repositories cannot release while the scaffold markers remain. Before releasing a derived plugin, pin an immutable Compose template tag and replace those markers with the application's supported migration and behavioral checks. Keep lifecycle orchestration in plugin metadata while putting container-side readiness, migration, and verification programs in the versioned Compose template, mounted read-only and invoked by stable paths.

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

The default build and test targets only download the module graph and never
rewrite `go.mod` or `go.sum`. Use `make deps-update` when intentionally changing
dependencies and `make mod-check` to reject tidy drift. `make work` is the
explicit local-development step that points the plugin at a sibling sitectl
checkout.

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
