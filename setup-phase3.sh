#!/bin/bash

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

step() { echo -e "\n  ${CYAN}▶ $1${RESET}"; }
ok()   { echo -e "  ${GREEN}✅ $1${RESET}"; }

echo ""
echo -e "  ${CYAN}🔐 IDP Platform — Phase 3 : HashiCorp Vault${RESET}"
echo ""

# ─── 1. Deploy Vault on Kubernetes ───────────────────────────────────────────
step "Deploying Vault on Kubernetes..."
kubectl apply -f vault/vault-deployment.yml

echo "  Waiting for Vault to be ready..."
kubectl wait --for=condition=available deployment/vault --timeout=120s
ok "Vault deployed"

# ─── 2. Port-forward Vault ───────────────────────────────────────────────────
step "Starting Vault port-forward..."
pkill -f "port-forward.*8200" 2>/dev/null || true
sleep 2
kubectl port-forward svc/vault 8200:8200 &
sleep 5
ok "Vault UI → http://localhost:8200 (token: root)"

# ─── 3. Configure Vault ───────────────────────────────────────────────────────
step "Configuring Vault..."
export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="root"

# Enable KV secrets engine v2
vault secrets enable -path=secret kv-v2 2>/dev/null || echo "  KV already enabled"

# ─── 4. Create policies ───────────────────────────────────────────────────────
step "Creating policies..."
vault policy write dev-policy vault/policies/dev-policy.hcl
vault policy write prod-policy vault/policies/prod-policy.hcl
ok "Policies created"

# ─── 5. Enable Kubernetes auth ────────────────────────────────────────────────
step "Enabling Kubernetes auth..."
vault auth enable kubernetes 2>/dev/null || echo "  K8s auth already enabled"

# Configure K8s auth
KUBE_HOST=$(kubectl config view --raw -o jsonpath='{.clusters[0].cluster.server}')
K8S_CA=$(kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d)

vault write auth/kubernetes/config \
  kubernetes_host="$KUBE_HOST" \
  kubernetes_ca_cert="$K8S_CA"

ok "Kubernetes auth configured"

# ─── 6. Create roles per environment ─────────────────────────────────────────
step "Creating Vault roles for each environment..."

vault write auth/kubernetes/role/dev \
  bound_service_account_names="deployer" \
  bound_service_account_namespaces="dev" \
  policies="dev-policy" \
  ttl="1h"

vault write auth/kubernetes/role/staging \
  bound_service_account_names="deployer" \
  bound_service_account_namespaces="staging" \
  policies="dev-policy" \
  ttl="1h"

vault write auth/kubernetes/role/prod \
  bound_service_account_names="deployer" \
  bound_service_account_namespaces="prod" \
  policies="prod-policy" \
  ttl="30m"

ok "Roles created (dev, staging, prod)"

# ─── 7. Seed example secrets ──────────────────────────────────────────────────
step "Creating example secrets..."

vault kv put secret/dev/sample-app \
  db_host="postgres-dev.local" \
  db_password="dev-password-123" \
  api_key="dev-api-key-abc" \
  environment="development"

vault kv put secret/staging/sample-app \
  db_host="postgres-staging.local" \
  db_password="staging-password-456" \
  api_key="staging-api-key-def" \
  environment="staging"

vault kv put secret/prod/sample-app \
  db_host="postgres-prod.local" \
  db_password="prod-password-789" \
  api_key="prod-api-key-ghi" \
  environment="production"

ok "Secrets created for dev, staging, prod"

# ─── 8. Test secret retrieval ─────────────────────────────────────────────────
step "Testing secret retrieval..."
echo ""
echo "  Dev secrets:"
vault kv get secret/dev/sample-app
echo ""

# ─── 9. Summary ───────────────────────────────────────────────────────────────
echo ""
echo -e "  ${GREEN}✅ Phase 3 complete!${RESET}"
echo ""
echo -e "  ${YELLOW}Vault UI:${RESET}     http://localhost:8200 (token: root)"
echo -e "  ${YELLOW}K8s Auth:${RESET}     enabled — pods authenticate via ServiceAccount"
echo -e "  ${YELLOW}Secrets:${RESET}      secret/dev/*, secret/staging/*, secret/prod/*"
echo -e "  ${YELLOW}Policies:${RESET}     dev-policy (read/list), prod-policy (read only)"
echo ""
echo -e "  ${YELLOW}Test a secret from a pod:${RESET}"
echo "  kubectl run vault-test --image=hashicorp/vault:1.15 -n dev --rm -it -- \\"
echo "    vault kv get -address=http://vault.default.svc.cluster.local:8200 secret/dev/sample-app"
echo ""
