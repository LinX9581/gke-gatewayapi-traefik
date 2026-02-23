{{- define "traefik-gatewayapi.fullname" -}}
{{- if .Values.gateway.name -}}
{{- .Values.gateway.name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-gateway" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "traefik-gatewayapi.traefikServiceName" -}}
{{- if .Values.edgeGateway.traefikService.name -}}
{{- .Values.edgeGateway.traefikService.name | trunc 63 | trimSuffix "-" -}}
{{- else if .Values.traefik.fullnameOverride -}}
{{- .Values.traefik.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "traefik-gatewayapi.traefikServiceNamespace" -}}
{{- if .Values.edgeGateway.traefikService.namespace -}}
{{- .Values.edgeGateway.traefikService.namespace -}}
{{- else -}}
{{- .Release.Namespace -}}
{{- end -}}
{{- end -}}
