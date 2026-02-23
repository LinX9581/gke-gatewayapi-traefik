#!/usr/bin/env bash
set -euo pipefail

info()  { echo "[INFO] $*"; }
warn()  { echo "[WARN] $*" >&2; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "[ERROR] missing command: $1" >&2
    exit 1
  }
}

need_cmd kubectl
need_cmd helm

EDGE_NAMESPACE="${EDGE_NAMESPACE:-default}"
EDGE_GATEWAY_NAME="${EDGE_GATEWAY_NAME:-app-gateway}"

TRAEFIK_NAMESPACE="${TRAEFIK_NAMESPACE:-traefik}"
TRAEFIK_RELEASE="${TRAEFIK_RELEASE:-traefik}"
TRAEFIK_GATEWAY_NAME="${TRAEFIK_GATEWAY_NAME:-traefik-gateway}"
TRAEFIK_GATEWAY_CLASS="${TRAEFIK_GATEWAY_CLASS:-traefik}"

TLS_SECRET_NAME="${TLS_SECRET_NAME:-linx-bar-tls}"

info "Deleting edge route resources..."
kubectl delete httproute edge-to-traefik -n "$EDGE_NAMESPACE" --ignore-not-found
kubectl delete referencegrant allow-default-httproute-to-traefik-svc -n "$TRAEFIK_NAMESPACE" --ignore-not-found
kubectl delete referencegrant allow-edge-httproute-to-traefik-svc -n "$TRAEFIK_NAMESPACE" --ignore-not-found

info "Deleting edge gateway + TLS secret..."
kubectl delete gateway "$EDGE_GATEWAY_NAME" -n "$EDGE_NAMESPACE" --ignore-not-found
kubectl delete secret "$TLS_SECRET_NAME" -n "$EDGE_NAMESPACE" --ignore-not-found

info "Deleting GKE HealthCheckPolicy (if exists)..."
kubectl delete healthcheckpolicy.networking.gke.io traefik-service-hc -n "$TRAEFIK_NAMESPACE" --ignore-not-found

info "Deleting Traefik Gateway + GatewayClass..."
kubectl delete gateway "$TRAEFIK_GATEWAY_NAME" -n "$TRAEFIK_NAMESPACE" --ignore-not-found
kubectl delete gatewayclass "$TRAEFIK_GATEWAY_CLASS" --ignore-not-found

info "Uninstalling Traefik Helm release..."
helm uninstall "$TRAEFIK_RELEASE" -n "$TRAEFIK_NAMESPACE" || warn "helm release not found or already removed"

info "Cleanup completed. You can now redeploy via ArgoCD."
