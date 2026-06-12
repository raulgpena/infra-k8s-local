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
