# base-app

Reusable base Helm chart for deploying an application on the local k3d cluster.
It renders a `Deployment` plus an optional `Service`, `Ingress`, and `Job`,
with the defaults required by `CLAUDE.md` (app/env labels, resource limits,
non-root, probes, no `:latest`).

## What it renders

| Resource | Toggle | Default |
|----------|--------|---------|
| Deployment | `deployment.enabled` | `true` |
| Service | `service.enabled` | `true` |
| Ingress | `ingress.enabled` | `false` |
| Job | `job.enabled` | `false` |

> Resource names default to `<release>-base-app`. Set `fullnameOverride` to pin
> a clean name (e.g. `api`).

## Usage

```bash
# render
helm template api k8s/helm/base-app -f my-values.yaml

# install into a namespace
helm install api k8s/helm/base-app -n snow-white --create-namespace -f my-values.yaml
```

## Per-service value examples

### api — Deployment + Service + Ingress

```yaml
fullnameOverride: api
project: snow-white
image:
  repository: ghcr.io/your-org/snow-white-api
  tag: "0.1.0"
service:
  enabled: true
ingress:
  enabled: true
  className: nginx
  host: snow-white-api.127.0.0.1.nip.io
```

### consumer — Deployment only (background worker)

```yaml
fullnameOverride: consumer
project: snow-white
image:
  repository: ghcr.io/your-org/snow-white-consumer
  tag: "0.1.0"
service:
  enabled: false
probes:
  enabled: true
  liveness:
    exec:
      command: ["cat", "/tmp/healthy"]
    initialDelaySeconds: 10
  readiness: null
```

### migration — Job only (Argo CD Sync hook)

```yaml
fullnameOverride: migration
project: snow-white
deployment:
  enabled: false
service:
  enabled: false
image:
  repository: ghcr.io/your-org/snow-white-migration
  tag: "0.1.0"
job:
  enabled: true
  argocdHook: true
  command: ["/bin/sh", "-c", "./migrate up"]
```

## Using it from Argo CD

Point an `Application`/`ApplicationSet` source at this chart path and supply the
per-service values, e.g. in the `infra-argocd-local` repo a service folder can
hold just a `values.yaml` and reference this chart via a multi-source Application.
