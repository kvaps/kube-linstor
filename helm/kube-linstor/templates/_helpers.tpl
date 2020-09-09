{{/* vim: set filetype=gohtmltmpl: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "linstor.name" -}}
{{- default "linstor" .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "linstor.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default "linstor" .Values.nameOverride -}}
{{- if or (contains $name .Release.Name) (eq (.Release.Name | upper) "RELEASE-NAME") -}}
{{- $name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Generates linstor.toml config file
*/}}
{{- define "linstor.controllerConfig" -}}
[db]
  user = "{{ .Values.controller.db.user }}"
  password = "{{ .Values.controller.db.password }}"
  connection_url = "{{ .Values.controller.db.connectionUrl }}"
[http]
  port = {{ .Values.controller.port }}
{{- if or .Values.controller.ssl.enabled }}
[https]
  enabled = true
  port = {{ .Values.controller.ssl.port }}
  keystore = "/config/ssl/keystore.jks"
  keystore_password = "linstor"
  truststore = "/config/ssl/trustore_client.jks"
  truststore_password = "linstor"
{{- end }}
{{ end }}

