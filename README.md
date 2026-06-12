<!--
  Name:       README.md
  Author:     Raul Pena (raul.pena@gmail.com)
  Created At: 06/11/2026
-->

# Local K8s Environment as Code (macOS · Rancher Desktop · k3d · Terraform)

Treat your MacBook like a cloud account. One command builds the whole thing,
one command destroys it. No manual steps.

## Architecture

| Layer | Cloud equivalent | Tool here |
|-------|------------------|-----------|
| Container engine | — | Rancher Desktop (moby/dockerd) |
| Cluster | EKS / GKE / AKS module | `k3d/cluster.yaml` (declarative) |
| Platform (ingress, certs, namespaces) | Terraform helm/k8s providers | `terraform/` — identical code style |
| Apps | Terraform / Helm / GitOps | `terraform/main.tf` (sample `whoami`) |
| Glue | CI pipeline | `Makefile` |

## Prerequisites

- Rancher Desktop running with **dockerd (moby)** as container engine
  (Preferences → Container Engine). Kubernetes in Rancher Desktop can stay
  disabled — k3d creates its own clusters and you avoid port conflicts.

## Usage

```bash
make tools     # one-time: brew bundle (k3d, kubectl, helm, terraform, ...)
make up        # cluster + ingress-nginx + cert-manager + sample app
curl http://whoami.127.0.0.1.nip.io
make status    # nodes & pods overview
make down      # remove workloads, keep cluster
make destroy   # remove everything
```

`make up` is idempotent — rerun it after changing any `.tf` file and only the
diff is applied, exactly like in the cloud.

## Local registry

The cluster ships with a registry:

```bash
docker build -t localhost:5050/myapp:dev .
docker push localhost:5050/myapp:dev
# in manifests / Terraform: image = "registry.localhost:5050/myapp:dev"
```

## Adding your own apps

Add `helm_release` or `kubernetes_*` resources to `terraform/main.tf`
(or split into modules — the same modules you use for cloud clusters work
here unchanged, since only the provider context differs). For per-env
differences, drive them with `var.environment` and tfvars files.

## Alternative: 100% Terraform (cluster included)

If you want the cluster itself inside Terraform (single `terraform apply`
for everything), there is a community provider:

```hcl
terraform {
  required_providers {
    k3d = {
      source  = "pvotal-tech/k3d"
      version = "~> 0.0.7"
    }
  }
}

resource "k3d_cluster" "local" {
  name    = "local-dev"
  servers = 1
  agents  = 2
}
```

It works, but it's community-maintained and lags behind k3d releases. The
`k3d config file + Terraform` split in this repo is the more robust pattern
and mirrors real cloud setups (cluster bootstrap vs. workloads in separate
state) — which also avoids the classic Terraform pitfall of creating a
cluster and configuring its providers in the same apply.

## Fast inner dev loop (optional)

For code-change → redeploy cycles on top of this environment, add
[Tilt](https://tilt.dev) or [Skaffold](https://skaffold.dev): Terraform owns
the platform, Tilt owns the rebuild/hot-reload loop of the app you're
actively coding.
