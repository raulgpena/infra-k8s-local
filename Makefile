# -----------------------------------------------------------------------------
# Name:       Makefile
# Author:     Raul Pena (raul.pena@gmail.com)
# Created At: 06/11/2026
# -----------------------------------------------------------------------------

CLUSTER      := local-dev
K3D_CONFIG   := k3d-config.yaml
TF_DIR       := infra/terraform

.PHONY: help tools up cluster platform down destroy status

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

tools: ## Install all CLI tooling via Homebrew
	brew bundle --file=Brewfile

up: cluster platform ## Create the full environment (cluster + platform + apps)
	@echo "Environment ready — try: curl http://whoami.127.0.0.1.nip.io"

cluster: ## Create the k3d cluster (idempotent)
	@k3d cluster list | grep -q "^$(CLUSTER)" || k3d cluster create --config $(K3D_CONFIG)

platform: ## Apply Terraform (namespaces, ingress, cert-manager, apps)
	cd $(TF_DIR) && terraform init -upgrade -input=false && terraform apply -auto-approve

down: ## Destroy Terraform resources but keep the cluster
	@echo "WARNING: This will destroy all Terraform-managed resources."
	@read -p "Continue? [y/N] " ans && [ "$$ans" = "y" ]
	cd $(TF_DIR) && terraform destroy -auto-approve

destroy: ## Nuke everything, including the cluster
	@echo "WARNING: This will destroy ALL resources including the k3d cluster."
	@read -p "Continue? [y/N] " ans && [ "$$ans" = "y" ]
	-cd $(TF_DIR) && terraform destroy -auto-approve
	-k3d cluster delete $(CLUSTER)
	@echo "Environment removed"

status: ## Quick health overview
	k3d cluster list
	kubectl --context k3d-$(CLUSTER) get nodes,pods -A
