# Policy for prod environment
# Read-only access to prod secrets

path "secret/data/prod/*" {
  capabilities = ["read"]
}

path "secret/metadata/prod/*" {
  capabilities = ["read", "list"]
}

# Deny all other paths
path "*" {
  capabilities = ["deny"]
}
