resource "kubernetes_namespace" "prometheus" {
  metadata {
    name = "prometheus"
  }
}

resource "kubernetes_secret" "ca" {
  metadata {
    name = "vault-tls"
    namespace = "prometheus"
  }

  data = {
    "vault-ca.crt" = tls_self_signed_cert.ca.cert_pem
  }
}

resource "helm_release" "prometheus" {
  name = "prometheus-community"
  namespace = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart = "kube-prometheus-stack"
  values = [<<EOF
alertmanager:
  ingress:
    enabled: true
    ingressClassName: alb
    annotations:
      external-dns.alpha.kubernetes.io/hostname: "${var.alertmanager_hostname}"
      alb.ingress.kubernetes.io/load-balancer-name: alertmanager
      alb.ingress.kubernetes.io/scheme: internal
      alb.ingress.kubernetes.io/ssl-redirect: '9093'
      alb.ingress.kubernetes.io/target-type: ip
      alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS": 9093}, {"HTTPS": 443}]'
      alb.ingress.kubernetes.io/backend-protocol: HTTP
      alb.ingress.kubernetes.io/certificate-arn: "${var.alertmanager_certificate}"
      alb.ingress.kubernetes.io/healthcheck-protocol: HTTP
      alb.ingress.kubernetes.io/healthcheck-port: '9093'
      alb.ingress.kubernetes.io/healthcheck-path: /-/healthy
    hosts:
      - "${var.alertmanager_hostname}"
    paths:
      - "/*"

kubeProxy:
  enabled: false

grafana:
  plugins:
    - grafana-piechart-panel
  ingress:
    enabled: true
    ingressClassName: alb
    annotations:
      external-dns.alpha.kubernetes.io/hostname: "${var.grafana_hostname}"
      alb.ingress.kubernetes.io/load-balancer-name: grafana
      alb.ingress.kubernetes.io/scheme: internal
      alb.ingress.kubernetes.io/ssl-redirect: '3000'
      alb.ingress.kubernetes.io/target-type: ip
      alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS": 3000}, {"HTTPS": 443}]'
      alb.ingress.kubernetes.io/backend-protocol: HTTP
      alb.ingress.kubernetes.io/certificate-arn: "${var.grafana_certificate}"
      alb.ingress.kubernetes.io/healthcheck-protocol: HTTP
      alb.ingress.kubernetes.io/healthcheck-port: '3000'
      alb.ingress.kubernetes.io/healthcheck-path: /api/health
    hosts:
      - "${var.grafana_hostname}"
    paths:
      - "/*"

prometheus:
  ingress:
    enabled: true
    ingressClassName: alb
    annotations:
      external-dns.alpha.kubernetes.io/hostname: "${var.prometheus_hostname}"
      alb.ingress.kubernetes.io/load-balancer-name: prometheus
      alb.ingress.kubernetes.io/scheme: internal
      alb.ingress.kubernetes.io/target-type: ip
      alb.ingress.kubernetes.io/ssl-redirect: '9090'
      alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS": 9090}, {"HTTPS": 443}]'
      alb.ingress.kubernetes.io/backend-protocol: HTTP
      alb.ingress.kubernetes.io/certificate-arn: "${var.prometheus_certificate}"
      alb.ingress.kubernetes.io/healthcheck-protocol: HTTP
      alb.ingress.kubernetes.io/healthcheck-port: '9090'
      alb.ingress.kubernetes.io/healthcheck-path: /-/healthy
    hosts:
      - "${var.prometheus_hostname}"
    paths:
      - "/*"
  prometheusSpec:
    secrets:
      - vault-tls
    additionalScrapeConfigs:
      - job_name: 'vault'
        metrics_path: '/v1/sys/metrics'
        params:
          format: ['prometheus']
        scheme: https
        tls_config:
          ca_file: '/etc/prometheus/secrets/vault-tls/vault-ca.crt'
          insecure_skip_verify: true
        kubernetes_sd_configs:
          - role: endpoints
        relabel_configs:
          - source_labels:
              [
                __meta_kubernetes_namespace,
                __meta_kubernetes_pod_container_port_number,
              ]
            action: keep
            regex: vault;8200
EOF
  ]
  depends_on = [
    kubernetes_namespace.prometheus,
  ]
}

resource "kubernetes_config_map" "grafana_dashboards" {
  metadata {
    name = "grafana-dashboards"
    namespace = "prometheus"
    labels = {
      grafana_dashboard: "1"
    }
  }
  data = {
    "vault.json" = file("grafana-dashboard-vault.json")
  }
}
