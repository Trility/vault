resource "kubernetes_namespace" "vault" {
  metadata {
    name = "vault"
  }
}

resource "kubernetes_secret" "tls" {
  metadata {
    name = "vault-tls"
    namespace = "vault"
  }

  data = {
    "ca.crt" = tls_self_signed_cert.ca.cert_pem
    "server.crt" = tls_locally_signed_cert.cert.cert_pem
    "server.key" = tls_private_key.cert.private_key_pem
  }
}

data "aws_s3_object" "vault_license" {
  count = var.vault_enterprise ? 1 : 0
  bucket = "hashicorp-demo-licenses"
  key = "vault-trility-nfr.hclic"
}

resource "kubernetes_secret" "license" {
  count = var.vault_enterprise ? 1 : 0
  metadata {
    name = "vault-license"
    namespace = "vault"
  }
  data = {
    "enterprise-license" = data.aws_s3_object.vault_license[0].key
  }
}

resource "helm_release" "vault" {
  name = "vault"
  namespace = "vault"
  repository = "https://helm.releases.hashicorp.com"
  chart = "vault"
  version = var.vault_helm_version
  values = [<<EOF
global:
  tlsDisable: false

server:
  enterpriseLicense:
    secretName: "${var.vault_secret_name}"
    secretKey: "license"
  
  image:
    repository: "${var.vault_repository}"
    tag: "${var.vault_version}"

  resources:
    requests:
      memory: "${var.vault_resources_requests_memory}"
      cpu: "${var.vault_resources_requests_cpu}"
    limits:
      memory: "${var.vault_resources_limits_memory}" 
      cpu: "${var.vault_resources_limits_cpu}"

  readinessProbe:
    enabled: true
    path: "/v1/sys/health?standbyok=true&sealedcode=204&uninitcode=204"
  livenessProbe:
    enabled: true
    initialDelaySeconds: 60

  ingress:
    enabled: true
    ingressClassName: "alb"
    annotations: |
      external-dns.alpha.kubernetes.io/hostname: "${var.vault_hostname}"
      alb.ingress.kubernetes.io/load-balancer-name: "vault"
      alb.ingress.kubernetes.io/scheme: "internal"
      alb.ingress.kubernetes.io/target-type: "ip"
      alb.ingress.kubernetes.io/ssl-redirect: "8200"
      alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS": 8200}, {"HTTPS": 443}]'
      alb.ingress.kubernetes.io/backend-protocol: "HTTPS"
      alb.ingress.kubernetes.io/certificate-arn: "${var.vault_certificate}"
      alb.ingress.kubernetes.io/healthcheck-protocol: "HTTPS"
      alb.ingress.kubernetes.io/healthcheck-port: "8200"
      alb.ingress.kubernetes.io/healthcheck-path: "/v1/sys/health?standbyok=true"
    hosts:
      - host: "${var.vault_hostname}"
        paths:
          - "/"
          - "/ui"

  extraEnvironmentVars:
    VAULT_CACERT: /vault/userconfig/vault-tls/ca.crt

  extraVolumes:
    - type: secret
      name: vault-tls

  serviceAccount:
    annotations: |
      eks.amazonaws.com/role-arn: "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/vault-unseal"

  auditStorage:
    enabled: true

  standalone:
    enabled: false

  ha:
    enabled: true
    replicas: 5
    raft:
      enabled: true
      setNodeId: true

      config: |
        ui = true
        listener "tcp" {
          address = "[::]:8200"
          cluster_address = "[::]:8201"
          telemetry {
            unauthenticated_metrics_access = "true"
          }
          tls_cert_file = "/vault/userconfig/vault-tls/server.crt"
          tls_key_file = "/vault/userconfig/vault-tls/server.key"
          tls_ca_cert_file = "/vault/userconfig/vault-tls/ca.crt"
        }

        telemetry {
          prometheus_retention_time = "30s"
          disable_hostname = true
        }

        storage "raft" {
          path = "/vault/data"
            retry_join {
            leader_api_addr = "https://vault-0.vault-internal:8200"
            leader_ca_cert_file = "/vault/userconfig/vault-tls/ca.crt"
            leader_client_cert_file = "/vault/userconfig/vault-tls/server.crt"
            leader_client_key_file = "/vault/userconfig/vault-tls/server.key"
          }
          retry_join {
            leader_api_addr = "https://vault-1.vault-internal:8200"
            leader_ca_cert_file = "/vault/userconfig/vault-tls/ca.crt"
            leader_client_cert_file = "/vault/userconfig/vault-tls/server.crt"
            leader_client_key_file = "/vault/userconfig/vault-tls/server.key"
          }
          retry_join {
            leader_api_addr = "https://vault-2.vault-internal:8200"
            leader_ca_cert_file = "/vault/userconfig/vault-tls/ca.crt"
            leader_client_cert_file = "/vault/userconfig/vault-tls/server.crt"
            leader_client_key_file = "/vault/userconfig/vault-tls/server.key"
          }
          retry_join {
              leader_api_addr = "https://vault-3.vault-internal:8200"
              leader_ca_cert_file = "/vault/userconfig/vault-tls/ca.crt"
              leader_client_cert_file = "/vault/userconfig/vault-tls/server.crt"
              leader_client_key_file = "/vault/userconfig/vault-tls/server.key"
          }
          retry_join {
              leader_api_addr = "https://vault-4.vault-internal:8200"
              leader_ca_cert_file = "/vault/userconfig/vault-tls/ca.crt"
              leader_client_cert_file = "/vault/userconfig/vault-tls/server.crt"
              leader_client_key_file = "/vault/userconfig/vault-tls/server.key"
          }

          autopilot {
            cleanup_dead_servers = "true"
            last_contact_threshold = "200ms"
            last_contact_failure_threshold = "10m"
            max_trailing_logs = 250000
            min_quorum = 5
            server_stabilization_time = "10s"
          }

        }

        service_registration "kubernetes" {}

        seal "awskms" {
          region = "${var.aws_region}"
          kms_key_id = "alias/vault-unseal"
        }
EOF
  ]
}
