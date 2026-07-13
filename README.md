# sitectl-app-tmpl

Template repository for a new Docker Compose-backed `sitectl` application plugin. Use it when an app has a standalone Compose template repository and needs app-specific create and rollout metadata, helpers, validation, debug output, health checks, and behavioral verification.

The scaffold requires stable `sitectl` v0.39.0 or newer. Its migration placeholder fails closed, its verification runner reports that behavioral verification is unfinished, and derived repositories cannot release while the scaffold markers remain. Before releasing a derived plugin, replace those markers with the application's supported migration and behavioral checks. Keep lifecycle steps in plugin metadata; do not delegate rollout to a downstream `scripts/rollout.sh`.

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

Full plugin authoring checklist and architecture notes:

https://sitectl.libops.io/contributing/app-template
