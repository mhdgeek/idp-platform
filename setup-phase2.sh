#!/bin/bash

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

step() { echo -e "\n  ${CYAN}▶ $1${RESET}"; }
ok()   { echo -e "  ${GREEN}✅ $1${RESET}"; }

echo ""
echo -e "  ${CYAN}🏗️  IDP Platform — Phase 2 : Terraform${RESET}"
echo ""

cd terraform

# ─── 1. Init ──────────────────────────────────────────────────────────────────
step "Initializing Terraform..."
terraform init
ok "Terraform initialized"

# ─── 2. Plan ──────────────────────────────────────────────────────────────────
step "Planning infrastructure..."
terraform plan -out=tfplan
ok "Plan generated"

# ─── 3. Apply ─────────────────────────────────────────────────────────────────
step "Applying infrastructure..."
terraform apply tfplan
ok "Infrastructure applied"

cd ..

# ─── 4. Verify ────────────────────────────────────────────────────────────────
step "Verifying..."
echo ""
echo "  Namespaces:"
kubectl get namespaces | grep -E "dev|staging|prod"
echo ""
echo "  Resource Quotas:"
kubectl get resourcequota -A | grep -E "dev|staging|prod"
echo ""
echo "  RBAC Roles:"
kubectl get roles -A | grep -E "dev|staging|prod"
echo ""
echo "  Network Policies:"
kubectl get networkpolicy -A | grep -E "dev|staging|prod"

echo ""
echo -e "  ${GREEN}✅ Phase 2 complete!${RESET}"
echo ""
echo -e "  ${YELLOW}What Terraform created:${RESET}"
echo "  • Namespaces with labels (managed-by=terraform)"
echo "  • Resource Quotas per env (dev < staging < prod)"
echo "  • Limit Ranges (default CPU/memory per container)"
echo "  • RBAC Roles (developer, viewer, admin)"
echo "  • ServiceAccount deployer per namespace"
echo "  • Network Policies (deny-all + allow same-ns + allow argocd)"
echo ""