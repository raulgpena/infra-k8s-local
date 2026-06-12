# -----------------------------------------------------------------------------
# Name:       main.tf
# Author:     Raul Pena (raul.pena@gmail.com)
# Created At: 06/11/2026
# -----------------------------------------------------------------------------

# ------------------------------------------------------------------
# Platform layer — same Terraform you would apply against a cloud
# cluster: namespaces, ingress controller, cert-manager.
# ------------------------------------------------------------------

resource "kubernetes_namespace" "apps" {
  metadata {
    name = "apps"
    labels = {
      environment = var.environment
      managed-by  = "terraform"
    }
  }
}

resource "kubernetes_namespace" "platform" {
  metadata {
    name = "platform"
    labels = {
      environment = var.environment
      managed-by  = "terraform"
    }
  }
}

# Ingress controller (k3d's built-in servicelb exposes type=LoadBalancer
# on the ports mapped in k3d-config.yaml, so localhost:80/443 just works)
resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.12.0"
  namespace  = kubernetes_namespace.platform.metadata[0].name

  set {
    name  = "controller.ingressClassResource.default"
    value = "true"
  }

  wait    = true
  timeout = 300
}

# cert-manager for local self-signed TLS (mirrors cloud setups using ACME)
resource "helm_release" "cert_manager" {
  count = var.enable_cert_manager ? 1 : 0

  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.16.3"
  namespace  = kubernetes_namespace.platform.metadata[0].name

  set {
    name  = "crds.enabled"
    value = "true"
  }

  wait    = true
  timeout = 300
}

# ------------------------------------------------------------------
# Sample workload — proves the whole chain end to end.
# Reachable at http://whoami.127.0.0.1.nip.io after `make up`.
# Replace/extend this with your real apps (helm_release or manifests).
# ------------------------------------------------------------------

resource "kubernetes_deployment" "whoami" {
  metadata {
    name      = "whoami"
    namespace = kubernetes_namespace.apps.metadata[0].name
    labels = {
      app = "whoami"
      env = var.environment
    }
  }

  spec {
    replicas = 2
    selector {
      match_labels = { app = "whoami" }
    }
    template {
      metadata {
        labels = {
          app = "whoami"
          env = var.environment
        }
      }
      spec {
        security_context {
          run_as_non_root = true
          run_as_user     = 1000
        }
        container {
          name  = "whoami"
          image = "traefik/whoami:v1.10"
          port {
            container_port = 80
          }
          resources {
            requests = {
              cpu    = "100m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "128Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "whoami" {
  metadata {
    name      = "whoami"
    namespace = kubernetes_namespace.apps.metadata[0].name
  }
  spec {
    selector = { app = "whoami" }
    port {
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_ingress_v1" "whoami" {
  metadata {
    name      = "whoami"
    namespace = kubernetes_namespace.apps.metadata[0].name
  }
  spec {
    rule {
      host = "whoami.127.0.0.1.nip.io"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.whoami.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.ingress_nginx]
}
