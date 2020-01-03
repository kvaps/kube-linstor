{{/* vim: set filetype=mustache: */}}
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
{{- $name := default "linstor" .Values.nameOverride -}}
{{- if eq (.Release.Name | upper) "RELEASE-NAME" -}}
{{- $name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "linstor.pskKey" -}}
{{- if .Values.stunnel.pskPass -}}
{{- printf "%s:%s\n" .Values.stunnel.pskUser .Values.stunnel.pskPass -}}
{{- else -}}
{{- printf "%s:%s\n" .Values.stunnel.pskUser (randAlphaNum 32) -}}
{{- end -}}
{{- end -}}
