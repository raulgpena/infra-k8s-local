{{/* Short name (defaults to chart name, overridable). */}}
{{- define "base-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Fully qualified resource name. */}}
{{- define "base-app.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/* Common labels (app + env required by CLAUDE.md, plus standard k8s labels). */}}
{{- define "base-app.labels" -}}
app: {{ include "base-app.name" . }}
env: {{ .Values.env }}
{{- if .Values.project }}
project: {{ .Values.project }}
{{- end }}
app.kubernetes.io/name: {{ include "base-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
{{- end -}}

{{/* Selector labels — stable subset, never include version/chart. */}}
{{- define "base-app.selectorLabels" -}}
app: {{ include "base-app.name" . }}
{{- end -}}
