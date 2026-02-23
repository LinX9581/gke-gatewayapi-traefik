{{- define "traefik-gatewayapi.fullname" -}}
{{- if .Values.gateway.name -}}
{{- .Values.gateway.name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-gateway" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
