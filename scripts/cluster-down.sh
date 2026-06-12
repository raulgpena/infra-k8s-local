#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Name:       cluster-down.sh
# Author:     Raul Pena (raul.pena@gmail.com)
# Created At: 06/11/2026
# -----------------------------------------------------------------------------
set -euo pipefail

k3d cluster delete local-dev
