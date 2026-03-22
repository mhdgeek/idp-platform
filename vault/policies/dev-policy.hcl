# Policy for dev environment
# Allows read access to dev secrets

path "secret/data/dev/*" {
  capabilities = ["read", "list"]
}

path "secret/metadata/dev/*" {
  capabilities = ["read", "list"]
}
