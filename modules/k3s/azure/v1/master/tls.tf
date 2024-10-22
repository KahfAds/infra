# Step 2: Generate a private key for the CA
resource "tls_private_key" "ca_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
# Step 3: Generate a self-signed CA certificate
resource "tls_self_signed_cert" "ca_cert" {
  private_key_pem = tls_private_key.ca_key.private_key_pem

  subject {
    common_name  = "server.kahf-ads.com"
    organization = "Kahf Ads"
  }
  is_ca_certificate = true

  validity_period_hours = 87600  # 10 years
  allowed_uses = [
    "cert_signing",
    "crl_signing",
    "key_encipherment",
    "digital_signature",
  ]
}

# Step 4: Generate a private key for the server
resource "tls_private_key" "server_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
# Step 5: Generate a server certificate signing request (CSR)
resource "tls_cert_request" "server_cert_request" {
  private_key_pem = tls_private_key.server_key.private_key_pem

  subject {
    common_name  = "server.kahf-ads.com"
    organization = "Kahf Ads"
  }
  ip_addresses = [azurerm_public_ip.primary.ip_address]
}
# Step 6: Sign the server CSR with the CA's private key
resource "tls_locally_signed_cert" "server_cert" {
  cert_request_pem   = tls_cert_request.server_cert_request.cert_request_pem
  ca_private_key_pem = tls_private_key.ca_key.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca_cert.cert_pem

  validity_period_hours = 8760  # 1 year
  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "server_auth"
  ]
}

# Step 7: Generate a private key for the client
resource "tls_private_key" "client_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
# Step 8: Generate a client certificate signed by the CA
resource "tls_cert_request" "client_cert_request" {
  private_key_pem = tls_private_key.client_key.private_key_pem

  subject {
    common_name  = "Terraform"
    organization = "kahf Ads"
  }
  ip_addresses = [azurerm_public_ip.primary.ip_address]
}
# Step 9: Sign the client certificate with the CA's private key
resource "tls_locally_signed_cert" "client_cert" {
  cert_request_pem = tls_cert_request.client_cert_request.cert_request_pem
  ca_private_key_pem = tls_private_key.ca_key.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca_cert.cert_pem

  validity_period_hours = 8760  # 1 year
  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "client_auth"
  ]
}
