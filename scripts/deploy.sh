#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Name:       deploy.sh
# Author:     Raul Pena (raul.pena@gmail.com)
# Created At: 06/11/2026
# -----------------------------------------------------------------------------
set -euo pipefail

kubectl apply -f k8s/
