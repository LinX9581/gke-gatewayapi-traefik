#!/usr/bin/env bash
SCRIPT_DIR="/etc/nginx/ssl"
EDGE_NAMESPACE="${EDGE_NAMESPACE:-default}"

echo "[INFO] 建立 TLS Secret..."
kubectl create secret tls linx-bar-tls \
  --cert="${SCRIPT_DIR}/linx-bar.crt" \
  --key="${SCRIPT_DIR}/linx-bar.key" \
  -n "$EDGE_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
