#!/bin/bash

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

step() { echo -e "\n  ${CYAN}▶ $1${RESET}"; }
ok()   { echo -e "  ${GREEN}✅ $1${RESET}"; }

echo ""
echo -e "  ${CYAN}🚀 IDP Platform — Phase 1 : Cluster + ArgoCD${RESET}"
echo ""

# ─── 1. Delete existing cluster ───────────────────────────────────────────────
step "Cleaning up any existing cluster..."
if kind get clusters 2>/dev/null | grep -q "idp-platform"; then
  kind delete cluster --name idp-platform
  ok "Old cluster deleted"
else
  ok "No existing cluster"
fi

# ─── 2. Create cluster ────────────────────────────────────────────────────────
step "Creating Kind cluster (1 control-plane + 3 workers)..."
kind create cluster --config cluster/kind-cluster.yml
ok "Cluster created"

# ─── 3. Namespaces ────────────────────────────────────────────────────────────
step "Creating namespaces (argocd, dev, staging, prod)..."
kubectl apply -f cluster/namespaces.yml
ok "Namespaces created"

# ─── 4. Install ArgoCD ────────────────────────────────────────────────────────
step "Installing ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "  Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=180s
ok "ArgoCD installed"

# ─── 5. Get ArgoCD password ───────────────────────────────────────────────────
step "Retrieving ArgoCD admin password..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)
echo ""
echo -e "  ${YELLOW}ArgoCD credentials:${RESET}"
echo "  URL      : http://localhost:8888"
echo "  Username : admin"
echo "  Password : $ARGOCD_PASSWORD"
echo ""

# ─── 6. Deploy root App of Apps ───────────────────────────────────────────────
step "Deploying root App of Apps..."
kubectl apply -f argocd/root-app.yml
ok "Root app deployed — ArgoCD will now sync everything from GitHub"

# ─── 7. Port-forward ArgoCD UI ────────────────────────────────────────────────
step "Starting ArgoCD port-forward..."
kubectl port-forward svc/argocd-server 8888:443 -n argocd &
sleep 3
ok "ArgoCD UI → http://localhost:8888"

# ─── 8. Summary ───────────────────────────────────────────────────────────────
echo ""
echo -e "  ${GREEN}✅ Phase 1 complete!${RESET}"
echo ""
echo "  Nodes:"
kubectl get nodes
echo ""
echo "  ArgoCD pods:"
kubectl get pods -n argocd
echo ""
echo -e "  ${YELLOW}Next steps:${RESET}"
echo "  1. Open http://localhost:8888 (admin / $ARGOCD_PASSWORD)"
echo "  2. Watch ArgoCD sync your apps from GitHub"
echo "  3. git push any change → ArgoCD deploys automatically"
echo ""
