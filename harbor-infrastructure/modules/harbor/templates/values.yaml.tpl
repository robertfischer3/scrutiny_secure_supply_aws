## Harbor Configuration File for S2C2F Compliance
## This template is used to generate values for the Harbor Helm chart

## Hostname configuration
externalURL: https://${harbor_domain}
harborAdminPassword: "{{ .Release.Name }}-{{ randAlphaNum 10 }}"

## Database configuration
database:
  type: ${database.type}
  %{ if database.type == "external" }
  external:
    host: ${database.host}
    port: ${database.port}
    username: ${database.username}
    password: ${database.password}
    database: ${database.database}
    sslmode: "require"
  %{ endif }

## Redis configuration
%{ if redis.type == "internal" }
redis:
  type: internal
  internal:
    host: ${redis.internal.host}
    port: ${redis.internal.port}
    password: ${redis.internal.password}
    database: ${redis.internal.database}
%{ else }
redis:
  type: ${redis.type}
  %{ if redis.type == "external" }
  external:
    host: ${redis.external.host}
    port: ${redis.external.port}
    password: ${redis.external.password}
    database: ${redis.external.database}
  %{ endif }
%{ endif }

## Storage Backend Configuration
persistence:
  enabled: ${persistence.enabled}
  resourcePolicy: "keep"
  persistentVolumeClaim:
    registry:
      storageClass: "${persistence.storage_class}"
      size: ${persistence.registry.size}
      accessMode: ReadWriteOnce
    %{ if enable_chartmuseum }
    chartmuseum:
      storageClass: "${persistence.storage_class}"
      size: ${persistence.chartmuseum.size}
      accessMode: ReadWriteOnce
    %{ endif }
    jobservice:
      storageClass: "${persistence.storage_class}"
      size: ${persistence.jobservice.size}
      accessMode: ReadWriteOnce
    %{ if redis.type == "internal" }
    redis:
      storageClass: "${persistence.storage_class}"
      size: ${persistence.redis.size}
      accessMode: ReadWriteOnce
    %{ endif }
    %{ if enable_trivy }
    trivy:
      storageClass: "${persistence.storage_class}"
      size: ${persistence.trivy.size}
      accessMode: ReadWriteOnce
    %{ endif }

## Storage Backend for Registry
registry:
  storage:
    %{ if storage_type == "filesystem" }
    filesystem:
      rootdirectory: /storage
    %{ endif }
    %{ if storage_type == "s3" }
    s3:
      region: ${s3.region}
      bucket: ${s3.bucket}
      %{ if s3.accesskey != "use_irsa" }
      accesskey: ${s3.accesskey}
      secretkey: ${s3.secretkey}
      %{ endif }
      %{ if s3.regionendpoint != "" }
      regionendpoint: ${s3.regionendpoint}
      %{ endif }
      encrypt: ${s3.encrypt}
      secure: ${s3.secure}
      skipverify: ${s3.skipverify}
      v4auth: ${s3.v4auth}
      chunksize: ${s3.chunksize}
      rootdirectory: ${s3.rootdirectory}
      storageclass: ${s3.storageclass}
      multipartcopythreshold: ${s3.multipartcopythreshold}
      multipartcopychunksize: ${s3.multipartcopychunksize}
      multipartcopymaxconcurrency: ${s3.multipartcopymaxconcurrency}
    %{ endif }
  resources:
    requests:
      memory: ${resources.registry.requests.memory}
      cpu: ${resources.registry.requests.cpu}
    limits:
      memory: ${resources.registry.limits.memory}
      cpu: ${resources.registry.limits.cpu}

## Notary configuration
notary:
  enabled: ${enable_notary}
  %{ if enable_notary }
  server:
    resources:
      requests:
        memory: "256Mi"
        cpu: "100m"
      limits:
        memory: "512Mi"
        cpu: "200m"
  signer:
    resources:
      requests:
        memory: "256Mi"
        cpu: "100m"
      limits:
        memory: "512Mi"
        cpu: "200m"
  %{ endif }

## Trivy vulnerability scanner
trivy:
  enabled: ${enable_trivy}
  %{ if enable_trivy }
  resources:
    requests:
      memory: ${resources.trivy.requests.memory}
      cpu: ${resources.trivy.requests.cpu}
    limits:
      memory: ${resources.trivy.limits.memory}
      cpu: ${resources.trivy.limits.cpu}
  %{ if additional_harbor_configs.trivy != null }
  gitHubToken: "${additional_harbor_configs.trivy.githubToken}"
  skipUpdate: ${additional_harbor_configs.trivy.skipUpdate}
  offlineScan: ${additional_harbor_configs.trivy.offline}
  %{ endif }
  %{ endif }

## Clair vulnerability scanner - typically use either Trivy or Clair, not both
clair:
  enabled: ${enable_clair}

## ChartMuseum for Helm chart repository
chartmuseum:
  enabled: ${enable_chartmuseum}
  %{ if enable_chartmuseum }
  resources:
    requests:
      memory: "256Mi"
      cpu: "100m"
    limits:
      memory: "512Mi"
      cpu: "200m"
  %{ endif }

## Core service
core:
  resources:
    requests:
      memory: ${resources.core.requests.memory}
      cpu: ${resources.core.requests.cpu}
    limits:
      memory: ${resources.core.limits.memory}
      cpu: ${resources.core.limits.cpu}
  %{ if additional_harbor_configs.log != null }
  logLevel: ${additional_harbor_configs.log.level}
  %{ endif }
  %{ if metrics.enabled }
  metrics:
    enabled: true
    path: ${metrics.core.path}
    port: ${metrics.core.port}
  %{ endif }

## JobService
jobservice:
  resources:
    requests:
      memory: ${resources.jobservice.requests.memory}
      cpu: ${resources.jobservice.requests.cpu}
    limits:
      memory: ${resources.jobservice.limits.memory}
      cpu: ${resources.jobservice.limits.cpu}
  %{ if metrics.enabled }
  metrics:
    enabled: true
    path: "/metrics"
    port: 8001
  %{ endif }

## Portal UI
portal:
  resources:
    requests:
      memory: "256Mi"
      cpu: "100m"
    limits:
      memory: "512Mi"
      cpu: "200m"

## Ingress Controller Configuration
expose:
  type: ${expose.type}
  tls:
    enabled: ${tls.enabled}
    %{ if tls.cert_source == "auto" }
    certSource: auto
    auto:
      commonName: "${tls.auto_cert.common_name}"
    %{ endif }
    %{ if tls.cert_source == "secret" }
    certSource: secret
    secret:
      secretName: "${tls.secret_name}"
      notarySecretName: "${tls.secret_name}"
    %{ endif }
    %{ if tls.cert_source == "none" }
    certSource: none
    %{ endif }
  %{ if expose.type == "ingress" }
  ingress:
    hosts:
      core: ${expose.ingress.harbor_host}
      %{ if enable_notary }
      notary: notary.${expose.ingress.harbor_host}
      %{ endif }
    annotations:
      %{ for key, value in expose.ingress.annotations }
      ${key}: "${value}"
      %{ endfor }
    controller: default
  %{ endif }

## Security and Audit Settings for S2C2F Compliance
%{ if additional_harbor_configs.log != null && additional_harbor_configs.log.audit != null && additional_harbor_configs.log.audit.enabled }
log:
  level: ${additional_harbor_configs.log.level}
  audit:
    enabled: true
%{ endif }

## Additional Harbor configurations from variables
%{ if additional_harbor_configs != null }
%{ for component, config in additional_harbor_configs }
%{ if component != "log" && component != "trivy" && component != "redis" }
${component}:
  %{ for key, value in config }
  %{ if value != null }
  %{ if value == true || value == false }
  ${key}: ${value}
  %{ else }
  ${key}: "${value}"
  %{ endif }
  %{ endif }
  %{ endfor }
%{ endif }
%{ endfor }
%{ endif }

## CSRF Protection
caSecretName: ${tls.ca_secret_name}
secretKey: "not-a-secure-key" # This will be overridden by Harbor to a generated key