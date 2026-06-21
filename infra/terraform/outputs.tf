# -----------------------------------------------------------------------------
# Name:       outputs.tf
# Author:     Raul Pena (raul.pena@gmail.com)
# Created At: 06/11/2026
# -----------------------------------------------------------------------------

output "sample_app_url" {
  value = "http://whoami.127.0.0.1.nip.io"
}

output "local_registry" {
  value = "push: localhost:5050  |  pull in-cluster: registry.localhost:5050"
}

output "argocd_url" {
  value = var.enable_argocd ? "http://${var.argocd_host}" : "argocd disabled"
}

output "argocd_admin_password_cmd" {
  description = "Command to fetch the auto-generated Argo CD admin password"
  value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}
