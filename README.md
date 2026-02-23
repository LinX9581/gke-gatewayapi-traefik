# traefik-template

最精簡的 Traefik + Gateway API Helm chart，可直接被 ArgoCD 以 Git path 部署。

## 目標
- 用 ArgoCD `app create` 直接部署
- 啟用 Traefik Gateway API provider
- 預設開啟 access log（JSON）
- 保留常用欄位：`User-Agent`、`Referer`、`X-Forwarded-For`、`X-Real-Ip`、client ip（`ClientAddr`）

## 結構
- `Chart.yaml`: 主 chart，依賴官方 `traefik` chart
- `values.yaml`: 預設值（已啟用 access log）
- `templates/gatewayclass.yaml`: Traefik GatewayClass
- `templates/gateway.yaml`: Traefik Gateway
- `templates/example-httproute.yaml`: 可選範例路由（預設關閉）
- `values/argocd-values.yaml`: 給 ArgoCD 的簡潔覆寫範例

## ArgoCD 部署

```bash
argocd app create "$APP_NAME" \
  --repo "$REPO_URL" \
  --path "$PATH_IN_REPO" \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace "$NAMESPACE" \
  --values "$VALUES_FILE" \
  --upsert
```

### 建議變數
- `PATH_IN_REPO=traefik-template`
- `VALUES_FILE=values/argocd-values.yaml`

## 注意
- 這個 chart 會建立 cluster-scoped `GatewayClass`（預設 `traefik`）。
- 若叢集中已存在同名 `GatewayClass` 且由其他 release 管理，請在 values 設定：

```yaml
gatewayClass:
  create: false
  name: traefik
```

## Node Pool 建議
- `core_nodes` 放平台元件（Traefik / ArgoCD / logging agent）
- `app_nodes` 放業務服務
- 目前此 chart 預設會把 Traefik 排到 `core_nodes`：

```yaml
traefik:
  nodeSelector:
    cloud.google.com/gke-nodepool: core_nodes
  tolerations:
    - key: dedicated
      operator: Equal
      value: core
      effect: NoSchedule
```

若你的 GKE node pool 實際名稱不是 `core_nodes`，請改成實際值。

## 後續接 ELK
目前 access log 已輸出到容器標準輸出（JSON）。
之後只要在叢集接上 log collector（例如 Fluent Bit / Vector / Filebeat）就能轉送到 ELK。
