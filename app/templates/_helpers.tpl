{{/* Generate common labels */}}
{{- define "app.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/name: {{ include "app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/* Chart name */}}
{{- define "app.name" -}}
{{ .Chart.Name }}
{{- end }}

{{/* Full name */}}
{{- define "app.fullname" -}}
{{ include "app.name" . }}-{{ .Release.Name }}
{{- end }}

{{/* Image pull secrets based on registry type */}}
{{- define "app.imagePullSecrets" -}}
{{- if eq .Values.image.registryType "ghcr" }}
{{- if .Values.externalSecrets.enabled }}
- name: ghcr-auth-secret
{{- end }}
{{- end }}
{{- end }}

{{/* Service account name */}}
{{- define "app.serviceAccountName" -}}
{{- if .Values.workloadIdentity.enabled }}
{{ .Values.workloadIdentity.serviceAccountName }}
{{- else }}
default
{{- end }}
{{- end }}
