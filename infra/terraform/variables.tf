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
  default     = "https://github.com/your-org/gitops-repo"
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
    { name = "team-a", description = "Team A applications" },
    { name = "team-b", description = "Team B applications" },
    { name = "platform", description = "Platform / shared services" },
  ]
}
