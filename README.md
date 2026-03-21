# 🏗️ Internal Developer Platform (IDP)

> A production-grade platform that lets developers deploy apps to Kubernetes with a single command — no K8s knowledge required.

## Quick Start

```bash
bash setup-phase1.sh
open http://localhost:8888   # ArgoCD UI (admin / see terminal)
```

## Project Structure

```
idp-platform/
├── cluster/
│   ├── kind-cluster.yml      # 4-node Kind cluster
│   └── namespaces.yml        # dev, staging, prod, argocd
├── argocd/
│   ├── root-app.yml          # App of Apps (entry point)
│   └── apps/
│       └── sample-app.yml    # ArgoCD apps per env
├── apps/
│   └── sample-app/
│       ├── dev/              # Dev manifests (1 replica)
│       └── staging/          # Staging manifests (2 replicas)
├── terraform/                # Phase 2
├── vault/                    # Phase 3
├── cli/                      # Phase 4
└── setup-phase1.sh
```

## Phases

| Phase | Description | Status |
|---|---|---|
| 1 | Cluster + ArgoCD GitOps | 🚧 In progress |
| 2 | Terraform + Helm | ⏳ Upcoming |
| 3 | HashiCorp Vault | ⏳ Upcoming |
| 4 | IDP CLI + Backstage | ⏳ Upcoming |
| 5 | Istio + OpenTelemetry | ⏳ Upcoming |
