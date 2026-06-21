# -----------------------------------------------------------------------------
# Name:       argocd.tf
# Author:     Raul Pena (raul.pena@gmail.com)
# Created At: 06/21/2026
# -----------------------------------------------------------------------------

# ------------------------------------------------------------------
# Argo CD — GitOps continuous delivery for Kubernetes.
# Installed via the official argo-helm chart into its own namespace
# (Argo CD expects to live in a dedicated namespace).
# Exposed through the nginx ingress at http://argocd.127.0.0.1.nip.io
# ------------------------------------------------------------------

resource "kubernetes_namespace" "argocd" {
  count = var.enable_argocd ? 1 : 0

  metadata {
    name = "argocd"
    labels = {
      environment = var.environment
      managed-by  = "terraform"
    }
  }
}

resource "helm_release" "argocd" {
  count = var.enable_argocd ? 1 : 0

  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version
  namespace  = kubernetes_namespace.argocd[0].metadata[0].name

  # Run the API server in insecure mode so TLS is terminated at the
  # nginx ingress (avoids the double-TLS / SSL-passthrough dance locally).
  set {
    name  = "configs.params.server\\.insecure"
    value = "true"
  }

  wait    = true
  timeout = 600
}

# ------------------------------------------------------------------
# Argo CD Apps — declaratively manages Argo CD Application / Project /
# ApplicationSet resources (the App-of-Apps pattern) via Helm.
# Define your apps in a values file and point argocd_apps_values_file
# at it; with no file the chart installs with no apps (a no-op).
# ------------------------------------------------------------------

resource "helm_release" "argocd_apps" {
  count = var.enable_argocd && var.enable_argocd_apps ? 1 : 0

  name       = "argocd-apps"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = var.argocd_apps_chart_version
  namespace  = kubernetes_namespace.argocd[0].metadata[0].name

  # Default: render projects + the discovery ApplicationSet from the template.
  # Override: point var.argocd_apps_values_file at your own values file.
  values = [
    var.argocd_apps_values_file != "" ? file(var.argocd_apps_values_file) : templatefile("${path.module}/argocd-apps-values.yaml.tftpl", {
      projects      = var.argocd_projects
      repo_url      = var.gitops_repo_url
      repo_revision = var.gitops_repo_revision
    })
  ]

  wait    = true
  timeout = 300

  # Argo CD CRDs (Application/AppProject) must exist before this applies.
  depends_on = [helm_release.argocd]
}

resource "kubernetes_ingress_v1" "argocd" {
  count = var.enable_argocd ? 1 : 0

  metadata {
    name      = "argocd-server"
    namespace = kubernetes_namespace.argocd[0].metadata[0].name
    annotations = {
      "nginx.ingress.kubernetes.io/backend-protocol" = "HTTP"
    }
  }

  spec {
    rule {
      host = var.argocd_host
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "argocd-server"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.argocd, helm_release.ingress_nginx]
}
