#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Name:       cluster-up.sh
# Author:     Raul Pena (raul.pena@gmail.com)
# Created At: 06/11/2026
# -----------------------------------------------------------------------------
set -euo pipefail

k3d cluster create --config k3d-config.yaml
