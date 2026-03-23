#!/bin/bash

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

step() { echo -e "\n  ${CYAN}▶ $1${RESET}"; }
ok()   { echo -e "  ${GREEN}✅ $1${RESET}"; }

echo ""
echo -e "  ${CYAN}🔭 IDP Platform — Phase 5 : Istio + OpenTelemetry${RESET}"
echo ""

# ─── 1. Install Istio ─────────────────────────────────────────────────────────
step "Installing Istio (minimal profile)..."
istioctl install -f istio/config/istio-operator.yml -y
ok "Istio installed"

# ─── 2. Enable sidecar injection on namespaces ────────────────────────────────
step "Enabling Istio sidecar injection..."
kubectl label namespace dev     istio-injection=enabled --overwrite
kubectl label namespace staging istio-injection=enabled --overwrite
kubectl label namespace prod    istio-injection=enabled --overwrite
ok "Sidecar injection enabled on dev, staging, prod"

# ─── 3. Deploy Jaeger + OpenTelemetry ────────────────────────────────────────
step "Deploying Jaeger + OpenTelemetry Collector..."
kubectl apply -f istio/telemetry/jaeger-otel.yml

echo "  Waiting for Jaeger..."
kubectl wait --for=condition=available deployment/jaeger -n observability --timeout=120s
ok "Jaeger deployed"

echo "  Waiting for OTel Collector..."
kubectl wait --for=condition=available deployment/otel-collector -n observability --timeout=120s
ok "OpenTelemetry Collector deployed"

# ─── 4. Restart deployments to inject sidecars ───────────────────────────────
step "Restarting deployments to inject Istio sidecars..."
kubectl rollout restart deployment -n dev
kubectl rollout restart deployment -n staging
ok "Deployments restarted with Envoy sidecar"

# ─── 5. Verify ────────────────────────────────────────────────────────────────
step "Verifying..."
echo ""
echo "  Istio pods:"
kubectl get pods -n istio-system
echo ""
echo "  Observability pods:"
kubectl get pods -n observability
echo ""
echo "  Dev pods (should show 2/2 — app + envoy sidecar):"
kubectl get pods -n dev

# ─── 6. Port-forwards ─────────────────────────────────────────────────────────
step "Starting port-forwards..."
pkill -f "port-forward.*16686" 2>/dev/null || true
kubectl port-forward svc/jaeger-ui 16686:16686 -n observability &
sleep 2
ok "Jaeger UI → http://localhost:16686"

# ─── 7. Generate some traces ──────────────────────────────────────────────────
step "Generating traces..."
kubectl port-forward svc/my-api 9090:80 -n dev &
sleep 3
for i in $(seq 1 10); do
  curl -s http://localhost:9090/ > /dev/null 2>&1 || true
done
ok "10 requests sent — check Jaeger UI"

echo ""
echo -e "  ${GREEN}✅ Phase 5 complete!${RESET}"
echo ""
echo -e "  ${YELLOW}Open these dashboards:${RESET}"
echo "  Jaeger traces    → http://localhost:16686"
echo "  ArgoCD           → https://localhost:8888"
echo "  Vault            → http://localhost:8200"
echo ""
echo -e "  ${YELLOW}Istio features active:${RESET}"
echo "  ✓ mTLS between all services (automatic)"
echo "  ✓ Distributed tracing via Envoy sidecars"
echo "  ✓ Traffic management (VirtualService + DestinationRule)"
echo "  ✓ Circuit breaker (outlierDetection)"
echo "  ✓ Access logs on all pods"
echo ""
