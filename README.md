# sitectl-app-tmpl

Template repository for a new Docker Compose-backed `sitectl` application plugin. Use it when an app has a standalone Compose template repository and needs app-specific create metadata, helpers, validation, debug output, and health checks.

Core lifecycle operations stay in `sitectl`:

```bash
sitectl create app-tmpl/default --path ./app --type local --checkout-source template --setup-only
sitectl compose up
sitectl compose logs -f
sitectl healthcheck
```

Development commands:

```bash
make work
make test
make install
```

Full plugin authoring checklist and architecture notes:

https://sitectl.libops.io/contributing/app-template
