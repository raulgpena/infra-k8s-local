<!--
  Name:       CLAUDE.md
  Author:     Raul Pena (raul.pena@gmail.com)
  Created At: 06/11/2026
-->

# CLAUDE.md — Local Development Guide

> Simple rules for working locally with Docker, k3d, Kubernetes and Terraform.

---

## 1. Local Context

```
Environment  : local
Stack        : Docker + k3d + Kubernetes + Terraform
OS           : Linux / macOS
Cluster      : k3d (local Kubernetes via Docker)
Registry     : local (k3d built-in) or localhost:5000
```

---

## 2. Repository Structure

```
.
├── infra/
│   └── terraform/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars.example
├── k8s/
│   ├── deployments/
│   ├── services/
│   ├── configmaps/
│   └── namespaces/
├── docker/
│   ├── Dockerfile
│   └── docker-compose.yml
├── scripts/
│   ├── cluster-up.sh       # create k3d cluster
│   ├── cluster-down.sh     # destroy k3d cluster
│   └── deploy.sh           # apply k8s manifests
├── .env.example            # variable names with placeholder values only
├── CLAUDE.md               # this file
└── README.md
```

**Naming conventions:**
- k3d cluster: `k3d-{project}-local` (e.g., `k3d-myapp-local`)
- Kubernetes namespaces: `{service}-local` (e.g., `api-local`)
- Docker images: `{service}:local` (e.g., `api:local`)
- Terraform workspace: `local`

---

## 3. Docker

### Rules
- Always use a specific base image tag — never `FROM node:latest` or `FROM ubuntu:latest`.
- Use multi-stage builds to keep the final image small.
- The app must run as a non-root user inside the container.
- `.dockerignore` must exist and exclude `node_modules`, `.git`, `.env`, `*.tfstate`.

### docker-compose for local development
- `docker-compose.yml` is for local development only — not for production.
- Use named volumes for databases so data survives container restarts.
- Services must have a `healthcheck` defined.
- Never hardcode passwords in `docker-compose.yml` — read from `.env` file.

```yaml
# Good pattern
services:
  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "postgres"]
      interval: 5s
      retries: 5
    volumes:
      - db-data:/var/lib/postgresql/data

volumes:
  db-data:
```

---

## 4. k3d

### Rules
- One k3d cluster per project — named `k3d-{project}-local`.
- Always define the cluster in a config file (`k3d-config.yaml`) not as a long CLI command.
- Map only the ports you actually need to localhost.
- Destroy and recreate the cluster when something is badly broken — it is cheap and fast.

### Recommended k3d config

```yaml
# k3d-config.yaml
apiVersion: k3d.io/v1alpha5
kind: Simple
metadata:
  name: myapp-local
servers: 1
agents: 2
ports:
  - port: 8080:80      # HTTP ingress
    nodeFilters:
      - loadbalancer
  - port: 8443:443     # HTTPS ingress
    nodeFilters:
      - loadbalancer
registries:
  create:
    name: registry.localhost
    host: "0.0.0.0"
    hostPort: "5000"
options:
  k3s:
    extraArgs:
      - arg: --disable=traefik    # disable default traefik if you bring your own ingress
        nodeFilters:
          - server:*
```

### Common commands

```bash
# Create cluster from config
k3d cluster create --config k3d-config.yaml

# Start / stop without destroying
k3d cluster stop myapp-local
k3d cluster start myapp-local

# Delete and recreate (clean slate)
k3d cluster delete myapp-local
k3d cluster create --config k3d-config.yaml

# Load a locally built image into the cluster (no push to registry needed)
k3d image import myapp-api:local -c myapp-local

# List clusters
k3d cluster list
```

---

## 5. Kubernetes

### Rules
- Always use a namespace — never deploy to `default`.
- Every manifest must have `app` and `env` labels at minimum.
- Resource requests and limits are required on every container, even locally — it builds the habit.
- Use `kubectl apply -f k8s/` to apply, never `kubectl create` for repeatable resources.
- Secrets must not be committed — use `.env` files or a local Vault (see §7).

### Minimal required labels

```yaml
labels:
  app: my-service
  env: local
  version: "1.0.0"
```

### Minimal deployment pattern

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-service
  namespace: my-service-local
spec:
  replicas: 1                      # 1 replica is fine locally
  selector:
    matchLabels:
      app: my-service
  template:
    metadata:
      labels:
        app: my-service
        env: local
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
      containers:
        - name: my-service
          image: my-service:local
          ports:
            - containerPort: 3000
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 256Mi
          livenessProbe:
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 5
          readinessProbe:
            httpGet:
              path: /ready
              port: 3000
            initialDelaySeconds: 3
          envFrom:
            - configMapRef:
                name: my-service-config
```

### Common commands

```bash
# Apply all manifests
kubectl apply -f k8s/

# Watch pods
kubectl get pods -n my-service-local -w

# Tail logs
kubectl logs -f deployment/my-service -n my-service-local

# Shell into a running pod
kubectl exec -it deployment/my-service -n my-service-local -- sh

# Describe a pod (for debugging)
kubectl describe pod -n my-service-local

# Delete all resources in a namespace (clean slate)
kubectl delete all --all -n my-service-local
```

---

## 6. Terraform

### Rules
- Always run `terraform fmt` before committing.
- Always run `terraform validate` before applying.
- Always review `terraform plan` output before running `terraform apply`.
- Never run `terraform destroy` without reading the plan output first.
- `terraform.tfvars` must be gitignored — use `terraform.tfvars.example` with placeholder values.
- State file (`terraform.tfstate`) must be gitignored — never commit it.

### Required `.gitignore` entries for Terraform

```
# Terraform
.terraform/
terraform.tfstate
terraform.tfstate.backup
terraform.tfvars
*.tfplan
.terraform.lock.hcl    # commit this one — it locks provider versions
```

Wait — `.terraform.lock.hcl` should be committed. It locks provider versions so the team uses the same providers. Everything else above stays gitignored.

### Local state is acceptable here

For local development, local state is fine. When you move to a shared or cloud environment, migrate to a remote backend (S3, Azure Storage, GCS).

### Minimal project structure

```hcl
# variables.tf
variable "project" {
  type    = string
  default = "myapp"
}

variable "environment" {
  type    = string
  default = "local"
}

# main.tf
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}
```

### Common commands

```bash
# First time setup
terraform init

# Format all files
terraform fmt -recursive

# Validate config
terraform validate

# Preview changes
terraform plan

# Apply changes
terraform apply

# Apply without confirmation prompt (scripts only — not for manual use)
terraform apply -auto-approve

# Destroy everything (dangerous — always read the plan)
terraform plan -destroy
terraform destroy
```

---

## 7. Secrets

### Rules
- Never commit secrets, passwords, or tokens — not even for local development.
- `.env` files are for local use only and must be gitignored.
- `.env.example` lives in the repo with placeholder values so others know what variables are needed.
- Never hardcode credentials in Terraform files, Kubernetes manifests, or Dockerfiles.

### Local secrets pattern

```bash
# .env.example  — committed to the repo
DB_PASSWORD=change-me
API_KEY=change-me
JWT_SECRET=change-me

# .env  — gitignored, each developer fills in their own values
DB_PASSWORD=mylocal_password_123
API_KEY=dev-key-abc
JWT_SECRET=local-secret-xyz
```

For anything more sensitive, use **HashiCorp Vault** locally via Docker:

```bash
# Run Vault in dev mode locally
docker run --rm -d \
  --name vault-local \
  -p 8200:8200 \
  -e VAULT_DEV_ROOT_TOKEN_ID=local-root-token \
  hashicorp/vault:latest server -dev
```

---

## 8. Makefile — Standard Targets

Every project must have a `Makefile` with at least these targets so any developer can get started without reading docs:

```makefile
.PHONY: help cluster-up cluster-down build deploy clean

help:           ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*##' Makefile | awk 'BEGIN {FS = ":.*##"}; {printf "  %-20s %s\n", $$1, $$2}'

cluster-up:     ## Create k3d cluster
	k3d cluster create --config k3d-config.yaml

cluster-down:   ## Destroy k3d cluster
	k3d cluster delete myapp-local

build:          ## Build Docker images
	docker build -t my-service:local -f docker/Dockerfile .

load:           ## Load images into k3d cluster
	k3d image import my-service:local -c myapp-local

deploy:         ## Apply all Kubernetes manifests
	kubectl apply -f k8s/

tf-init:        ## Terraform init
	cd infra/terraform && terraform init

tf-plan:        ## Terraform plan
	cd infra/terraform && terraform plan

tf-apply:       ## Terraform apply
	cd infra/terraform && terraform apply

clean:          ## Destroy cluster and clean local state
	k3d cluster delete myapp-local
	rm -rf infra/terraform/.terraform
```

---

## 9. Observability (local)

No need for a full observability stack locally. Keep it simple:

- Use **structured JSON logs** in your app — same format as production, good habit.
- Run a lightweight **Prometheus + Grafana** stack via docker-compose for metrics if needed.
- Use `kubectl logs` and `kubectl describe` for debugging before reaching for anything heavier.

```yaml
# docker-compose.observability.yml — optional, start only when needed
services:
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./docker/prometheus.yml:/etc/prometheus/prometheus.yml

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      GF_SECURITY_ADMIN_PASSWORD: local
```

Start it only when you need it:
```bash
docker compose -f docker-compose.observability.yml up -d
```

---

## 10. AI-Assisted Work (Claude)

### What Claude can do
- Generate and explain Terraform configs, Kubernetes manifests, and Dockerfiles.
- Help debug `kubectl`, `k3d`, `docker`, and `terraform` errors.
- Suggest improvements to the local dev setup.
- Write Makefile targets and helper scripts.

### What Claude must not do
- Never hardcode secrets or passwords in any generated file.
- Never run `terraform destroy` or `kubectl delete namespace` without showing a warning first.
- Never use `latest` image tags in generated Kubernetes manifests or Dockerfiles.
- Never skip resource requests/limits in generated Kubernetes manifests.

### How Claude should work here
- Keep suggestions simple and local-first — no cloud services unless explicitly asked.
- Prefer `make {target}` commands over long CLI one-liners.
- When generating Terraform, always include `terraform fmt` and `terraform validate` as the first suggested step.
- When something is broken, suggest `kubectl describe` and `kubectl logs` before anything else.

---

*Simple local dev setup — Docker + k3d + Kubernetes + Terraform.*
