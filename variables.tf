variable "alertmanager_certificate" {}
variable "alertmanager_hostname" {}
variable "aws_region" {}
variable "eks_cluster_name" {}
variable "grafana_certificate" {}
variable "grafana_hostname" {}
variable "kms_user" {}
variable "openid_arn" {}
variable "openid_url" {}
variable "prometheus_certificate" {}
variable "prometheus_hostname" {}
variable "vault_certificate" {}
variable "vault_enterprise" {
  type = bool
}
variable "vault_helm_version" {}
variable "vault_hostname" {}
variable "vault_repository" {}
variable "vault_resources_requests_memory" {}
variable "vault_resources_requests_cpu" {}
variable "vault_resources_limits_memory" {}
variable "vault_resources_limits_cpu" {}
variable "vault_secret_name" {}
variable "vault_version" {}