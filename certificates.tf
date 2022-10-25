resource "tls_private_key" "ca" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "ca" {
  private_key_pem = tls_private_key.ca.private_key_pem
  is_ca_certificate = true
  validity_period_hours = 87600

  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]

  subject {
    organization = "vault"
    common_name = "Vault Internal TLS"
    country = "United States"
  }
}

resource "tls_private_key" "cert" {
  algorithm = "RSA"
}

resource "tls_cert_request" "cert" {
  private_key_pem = tls_private_key.cert.private_key_pem

  dns_names = [
    "vault",
    "vault-0.vault-internal",
    "vault-1.vault-internal",
    "vault-2.vault-internal",
    "vault-4.vault-internal",
    "vault-4.vault-internal",
  ]

  ip_addresses = [
    "127.0.0.1",
  ]

  subject {
    common_name = "vault"
    organization = "Vault Internal TLS"
  }
}

resource "tls_locally_signed_cert" "cert" {
  cert_request_pem = tls_cert_request.cert.cert_request_pem
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = 87600
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "client_auth",
    "server_auth",
  ]
}

#resource "local_file" "ca-crt" {
#  filename = "tls/ca.crt"
#  content  = tls_self_signed_cert.ca.cert_pem
#}
