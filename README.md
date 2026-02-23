# traefik-template

最精簡的 Traefik + Gateway API Helm chart，可直接被 ArgoCD 以 Git path 部署。

## 目標
- 用 ArgoCD `app create` 直接部署
- 內層：Traefik Gateway API
- 外層：GKE Gateway（80/443 + TLS）轉發到 Traefik
- 預設開啟 access log（JSON）

## 結構
- `Chart.yaml`: 主 chart，依賴官方 `traefik` chart
- `values.yaml`: 唯一 values 檔（ArgoCD 與本地共用）
- `templates/gatewayclass.yaml`: Traefik GatewayClass
- `templates/gateway.yaml`: Traefik Gateway（內層）
- `templates/edge-gateway.yaml`: GKE Gateway（外層）
- `templates/edge-route-to-traefik.yaml`: 外層 HTTPRoute + ReferenceGrant
- `templates/edge-healthcheckpolicy.yaml`: Traefik Service HealthCheckPolicy
- `shell/create_tls_secret.sh`: 建立 TLS Secret
- `shell/cleanup_gatewayapi_resources.sh`: 清理舊資源

## 部署順序
1. 先建立 TLS Secret（預設放在 `default` namespace）：

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
  --upsert
```

3. 同步：

```bash
argocd app sync traefik-gatewayapi
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

## Node Pool 建議
- `core_nodes` 放平台元件（Traefik / ArgoCD / logging agent）
- `app_nodes` 放業務服務
- 目前預設用 `workload=core` + `dedicated=core:NoSchedule` 放 Traefik 到 core 節點

## 後續接 ELK
目前 access log 已輸出到容器標準輸出（JSON）。
之後可接 Fluent Bit / Vector / Filebeat 轉送到 ELK。

## Access Log 欄位對照
- 已預設保留對應 Nginx `main` 的核心欄位：
  - `ClientAddr`（真實 client IP；不輸出整串 `X-Forwarded-For`）
  - `OriginDuration`（對應 upstream response time）
  - `StartLocal`（搭配 `TZ=Asia/Taipei`）
  - `RequestHost` / `RequestMethod` / `RequestPath` / `RequestProtocol`
  - `DownstreamStatus` / `DownstreamContentSize`
  - `request_Referer` / `request_User-Agent`
- Traefik 無原生 `upstream_cache_status` 欄位。
