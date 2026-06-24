# -----------------------------------------------------------------------------
# Name:       argocd-repos.tf
# Author:     Raul Pena (raul.pena@gmail.com)
# Created At: 06/21/2026
# -----------------------------------------------------------------------------

# ------------------------------------------------------------------
# Register repositories with Argo CD as repository secrets.
# Argo CD discovers any Secret in its namespace labelled
# argocd.argoproj.io/secret-type=repository.
#
# Credentials come from variables (sensitive); leave them empty for
# public repos — the secret still registers the repo (required so
# Argo CD knows the OCI registry hosts Helm charts).
# ------------------------------------------------------------------

# The gitops repo: scanned by the ApplicationSet and used as the
# values source for every app (Argo CD matches it by URL).
resource "kubernetes_secret" "gitops_repo" {
  count = var.enable_argocd && var.enable_argocd_apps ? 1 : 0

  metadata {
    name      = "argocd-repo-gitops"
    namespace = kubernetes_namespace.argocd[0].metadata[0].name
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = merge(
    {
      type = "git"
      url  = var.gitops_repo_url
    },
    var.gitops_repo_username != "" ? { username = var.gitops_repo_username } : {},
    var.gitops_repo_password != "" ? { password = var.gitops_repo_password } : {},
  )
}

# The base-app Helm chart hosted on GitHub Packages (ghcr OCI).
resource "kubernetes_secret" "base_app_registry" {
  count = var.enable_argocd && var.enable_argocd_apps ? 1 : 0

  metadata {
    name      = "argocd-repo-base-app"
    namespace = kubernetes_namespace.argocd[0].metadata[0].name
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = merge(
    {
      type      = "helm"
      name      = var.base_app_chart_name
      url       = var.base_app_chart_repo
      enableOCI = "true"
    },
    var.ghcr_username != "" ? { username = var.ghcr_username } : {},
    var.ghcr_password != "" ? { password = var.ghcr_password } : {},
  )
}
