#!/bin/bash

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

step() { echo -e "\n  ${CYAN}▶ $1${RESET}"; }
ok()   { echo -e "  ${GREEN}✅ $1${RESET}"; }

echo ""
echo -e "  ${CYAN}🛠️  IDP Platform — Phase 4 : IDP CLI${RESET}"
echo ""

# ─── 1. Setup Python venv ────────────────────────────────────────────────────
step "Setting up Python environment..."
cd cli
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt -q
ok "Dependencies installed"

# ─── 2. Make CLI executable ──────────────────────────────────────────────────
step "Installing IDP CLI..."
chmod +x idp.py

# Create alias
echo ""
echo -e "  ${YELLOW}Add this to your ~/.zshrc for permanent access:${RESET}"
echo "  alias idp='$(pwd)/.venv/bin/python $(pwd)/idp.py'"
echo ""

# Temporary alias for this session
alias idp="$(pwd)/.venv/bin/python $(pwd)/idp.py"
ok "CLI ready"

cd ..

# ─── 3. Demo ─────────────────────────────────────────────────────────────────
step "Running demo..."
echo ""

# Deploy a test app to dev
echo -e "  ${CYAN}$ idp deploy --app my-api --env dev --replicas 2${RESET}"
cli/.venv/bin/python cli/idp.py deploy --app my-api --env dev --replicas 2

echo ""
echo -e "  ${CYAN}$ idp status --app my-api --env dev${RESET}"
sleep 3
cli/.venv/bin/python cli/idp.py status --app my-api --env dev

echo ""
echo -e "  ${CYAN}$ idp list${RESET}"
cli/.venv/bin/python cli/idp.py list

echo ""
echo -e "  ${GREEN}✅ Phase 4 complete!${RESET}"
echo ""
echo -e "  ${YELLOW}Try it yourself:${RESET}"
echo "  source cli/.venv/bin/activate"
echo "  python cli/idp.py deploy --app mon-api --env staging --replicas 3"
echo "  python cli/idp.py deploy --app mon-api --env dev --dry-run"
echo "  python cli/idp.py list"
echo "  python cli/idp.py status --app mon-api --env staging"
echo "  python cli/idp.py logs --app mon-api --env dev"
echo ""
