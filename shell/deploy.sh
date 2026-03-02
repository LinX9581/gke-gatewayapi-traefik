#!/usr/bin/env bash
set -euo pipefail

APP_NAME="${APP_NAME:-traefik-gatewayapi}"
APP_REPO="${APP_REPO:-https://github.com/LinX9581/traefik-gatewayapi}"
APP_PATH="${APP_PATH:-.}"
DEST_SERVER="${DEST_SERVER:-https://kubernetes.default.svc}"
DEST_NAMESPACE="${DEST_NAMESPACE:-traefik}"
EDGE_GATEWAY_NAMESPACE="${EDGE_GATEWAY_NAMESPACE:-default}"
EDGE_GATEWAY_NAME="${EDGE_GATEWAY_NAME:-app-gateway}"
GATEWAY_WAIT_SECONDS="${GATEWAY_WAIT_SECONDS:-600}"

argocd app create "${APP_NAME}" \
  --repo "${APP_REPO}" \
  --path "${APP_PATH}" \
  --dest-server "${DEST_SERVER}" \
  --dest-namespace "${DEST_NAMESPACE}" \
  --upsert

argocd app sync "${APP_NAME}"

wait_for_gateway_ip() {
  local ns="$1" name="$2" timeout="$3"
  local elapsed=0 ip=""

  while (( elapsed < timeout )); do
    ip="$(kubectl get gateway "${name}" -n "${ns}" -o jsonpath='{.status.addresses[0].value}' 2>/dev/null || true)"
    if [[ -n "${ip}" ]]; then
      echo "${ip}"
      return 0
    fi

    sleep 5
    elapsed=$((elapsed + 5))
  done

  return 1
}

if ! dns_ip="$(wait_for_gateway_ip "${EDGE_GATEWAY_NAMESPACE}" "${EDGE_GATEWAY_NAME}" "${GATEWAY_WAIT_SECONDS}")"; then
  echo "[ERROR] Gateway ${EDGE_GATEWAY_NAMESPACE}/${EDGE_GATEWAY_NAME} did not get an external IP within ${GATEWAY_WAIT_SECONDS}s." >&2
  echo "[ERROR] Refusing to guess from other LoadBalancer services to avoid wrong DNS target." >&2
  echo "[HINT] Check: kubectl describe gateway ${EDGE_GATEWAY_NAME} -n ${EDGE_GATEWAY_NAMESPACE}" >&2
  exit 1
fi

echo "DNS Bind IP     : ${dns_ip}"
