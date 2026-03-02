# traefik-template

最精簡的 Traefik + Gateway API Helm chart，可直接被 ArgoCD 以 Git path 部署。

## 目標
- 用 ArgoCD `app create` 直接部署
- 內層：Traefik Gateway API
- 外層：GKE Gateway（80/443 + TLS）轉發到 Traefik
- HTTP → HTTPS 自動重導向（301）
- 預設開啟 access log（JSON）

## 結構
- `Chart.yaml`: 主 chart，依賴官方 `traefik` chart
- `values.yaml`: 唯一 values 檔（ArgoCD 與本地共用）
- `templates/gatewayclass.yaml`: Traefik GatewayClass
- `templates/gateway.yaml`: Traefik Gateway（內層）
- `templates/edge-gateway.yaml`: GKE Gateway（外層）
- `templates/edge-route-to-traefik.yaml`: 外層 HTTPRoute + ReferenceGrant
- `templates/edge-http-to-https.yaml`: HTTP → HTTPS 301 重導向
- `templates/edge-healthcheckpolicy.yaml`: Traefik Service HealthCheckPolicy
- `shell/create_tls_secret.sh`: 建立 TLS Secret
- `shell/uninstall.sh`: 移除gatewayapi資源

## 部署順序
1. 先建立 TLS Secret（預設放在 `default` namespace）：
要準備 SSL crt key 預設讀取 /etc/nginx/ssl/
```bash
bash shell/create_tls_secret.sh
```

2. 再用 ArgoCD 建立/更新 App：

```bash
argocd app create "traefik-gatewayapi" \
  --repo "https://github.com/LinX9581/traefik-gatewayapi" \
  --path "." \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace "traefik" \
  --sync-option CreateNamespace=true \
  --upsert
```

3. 同步：

```bash
argocd app sync traefik-gatewayapi
```

4. 取得 Gateway IP

```bash
kubectl get gateway app-gateway -n default -o jsonpath='{.status.addresses[0].value}'
```

## 重要設定（values.yaml）
- `gateway.listeners[0].port=8000`：對齊 Traefik `web` entryPoint
- `traefik.additionalArguments` 需包含 `--ping.entryPoint=traefik`（配合 Pod readiness probe）
- `edgeGateway.className=gke-l7-global-external-managed`
- `edgeGateway.healthCheckPolicy.portSpecification=USE_FIXED_PORT` 且 `port=8080`（外層檢查 Traefik `/ping`）
- `edgeGateway.tls.secretName=linx-bar-tls`
- `edgeGateway.route.hostnames=[]`：可填 `nodejs.linx.bar`

範例：

```yaml
edgeGateway:
  route:
    hostnames:
      - nodejs.linx.bar
```

## Node Pool
省成本的關係 Traefik 和 elstic-agent 都裝在 AP node

## Access Log
access log 設定統一在 `values.yaml` 的 `traefik.logs.access` 區塊管理（JSON 格式）。
已輸出到容器標準輸出，可接 Fluent Bit / Vector / Filebeat 轉送到 ELK。

### 保留欄位對照
- `request_CF-Connecting-IP`（真實來源 IP）
- `OriginDuration`（對應 upstream response time）
- `StartLocal`（搭配 `TZ=Asia/Taipei`）
- `RequestHost` / `RequestMethod` / `RequestPath` / `RequestProtocol`
- `DownstreamStatus` / `DownstreamContentSize`
- `request_Referer` / `request_User-Agent`
- Traefik 無原生 `upstream_cache_status` 欄位。
