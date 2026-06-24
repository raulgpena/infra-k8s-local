# -----------------------------------------------------------------------------
# Name:       variables.tf
# Author:     Raul Pena (raul.pena@gmail.com)
# Created At: 06/11/2026
# -----------------------------------------------------------------------------

variable "kube_context" {
  description = "Kubeconfig context for the local cluster (k3d prefixes cluster names with 'k3d-')"
  type        = string
  default     = "k3d-local-dev"
}

variable "environment" {
  description = "Logical environment name applied as a label everywhere"
  type        = string
  default     = "local"
}

variable "enable_cert_manager" {
  description = "Install cert-manager (self-signed local TLS)"
  type        = bool
  default     = true
}

variable "enable_argocd" {
  description = "Install Argo CD (GitOps continuous delivery)"
  type        = bool
  default     = true
}

variable "argocd_chart_version" {
  description = "Version of the argo-cd Helm chart (argoproj.github.io/argo-helm)"
  type        = string
  default     = "7.7.11"
}

variable "argocd_host" {
  description = "Hostname the Argo CD UI is exposed on via the nginx ingress"
  type        = string
  default     = "argocd.127.0.0.1.nip.io"
}

variable "enable_argocd_apps" {
  description = "Install the argocd-apps chart (declarative Application/Project/ApplicationSet resources)"
  type        = bool
  default     = true
}

variable "argocd_apps_chart_version" {
  description = "Version of the argocd-apps Helm chart (argoproj.github.io/argo-helm)"
  type        = string
  default     = "2.0.2"
}

variable "argocd_apps_values_file" {
  description = "Override path to a Helm values file for argocd-apps; empty uses the generated template (argocd-apps-values.yaml.tftpl)"
  type        = string
  default     = ""
}

variable "gitops_repo_url" {
  description = "Git repository Argo CD reads applications from (the source of truth for app folders)"
  type        = string
  default     = "https://github.com/raulgpena/infra-argocd-local"
}

variable "gitops_repo_revision" {
  description = "Git revision (branch/tag) Argo CD tracks in the gitops repo"
  type        = string
  default     = "main"
}

variable "argocd_projects" {
  description = "AppProjects to create. Apps live under apps/<project>/<app>/ in the gitops repo and are mapped to the matching project."
  type = list(object({
    name        = string
    description = optional(string, "")
  }))
  default = [
    { name = "snow-white", description = "Snow White" },
    { name = "cars", description = "Cars" },
    { name = "hercules", description = "Hercules" },
  ]
}

variable "base_app_chart_repo" {
  description = "OCI registry path hosting the base-app chart (GitHub Packages / ghcr). No oci:// prefix."
  type        = string
  default     = "ghcr.io/raulgpena/charts"
}

variable "base_app_chart_name" {
  description = "Name of the reusable base application Helm chart"
  type        = string
  default     = "base-app"
}

variable "base_app_chart_version" {
  description = "Version of the base-app chart used to render each app"
  type        = string
  default     = "0.1.0"
}

# --- Argo CD repository credentials (leave empty for public repos) ---

variable "gitops_repo_username" {
  description = "Username for the gitops Git repo (empty for public repos)"
  type        = string
  default     = ""
}

variable "gitops_repo_password" {
  description = "Password/PAT for the gitops Git repo (empty for public repos)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ghcr_username" {
  description = "GitHub username to pull the base-app chart from ghcr (empty if the package is public)"
  type        = string
  default     = "raulgpena"
}

variable "ghcr_password" {
  description = "GitHub token with read:packages to pull base-app from ghcr (empty if the package is public)"
  type        = string
  default     = ""
  sensitive   = true
}
