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
