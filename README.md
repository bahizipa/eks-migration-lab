# EKS Migration Lab — "OVH ➜ AWS EKS" in miniature

A small, realistic sandbox that mirrors the shape of a Clearnox-style migration:
a legacy app running on a single Docker host ("OVH") is moved to a
Terraform-provisioned EKS cluster, deployed via GitOps (ArgoCD), with its
database moved to RDS and a controlled cutover.

You get to practise exactly what the interview will probe: AWS networking/IAM,
EKS operations, GitOps, data migration and cutover discipline.

## Architecture

```
 LEGACY ("OVH")                          TARGET (AWS)
 ┌──────────────────────┐                ┌────────────────────────────────────┐
 │ Docker host          │                │ VPC 10.0.0.0/16 (2 AZ)             │
 │  notes-api (Flask)   │   migrate      │  ┌──────────────┐  ┌────────────┐  │
 │  postgres:16         │ ───────────►   │  │ EKS 1.31     │  │ RDS        │  │
 │  docker compose      │                │  │ mng t3.small │──│ Postgres16 │  │
 └──────────────────────┘                │  │ ArgoCD       │  │ t4g.micro  │  │
                                         │  │ notes-api    │  └────────────┘  │
                                         │  └──────┬───────┘   ECR            │
                                         └─────────┼──────────────────────────┘
                                                   ▼  NLB (Service LoadBalancer)
```

## Phases (mirror a real engagement)

| Phase | What you do | Folder |
|---|---|---|
| 0. Discover | Run the legacy stack, document it | `legacy/` |
| 1. Land | Terraform VPC, EKS, RDS, ECR | `terraform/` |
| 2. Containerise & push | Build image, push to ECR | `scripts/01-build-push.sh` |
| 3. GitOps | Install ArgoCD, point it at this repo | `scripts/02-bootstrap-argocd.sh`, `gitops/` |
| 4. Migrate data | pg_dump legacy ➜ RDS | `scripts/03-migrate-db.sh` |
| 5. Cut over & verify | Smoke test, compare, switch traffic | `scripts/04-cutover-check.sh` |
| 6. Decommission | Stop legacy, destroy when done | `docs/MIGRATION-PLAN.md` |

## Prerequisites

- AWS account + `aws` CLI configured (an admin-ish IAM user/role for the lab)
- Terraform ≥ 1.6, kubectl, Helm, Docker, `psql`/`pg_dump` (Postgres 16 client)
- A GitHub repo: push this folder there and set `GITOPS_REPO_URL` in `scripts/env.sh`

## Quick start

```bash
# Phase 0 — legacy
cd legacy && docker compose up -d && curl localhost:8080/notes && cd ..

# Phase 1 — landing zone (≈ 15 min)
cd terraform && terraform init && terraform apply && cd ..
aws eks update-kubeconfig --region eu-west-1 --name notes-lab

# Phase 2..5
cp scripts/env.example.sh scripts/env.sh   # edit values
./scripts/01-build-push.sh
./scripts/02-bootstrap-argocd.sh
./scripts/03-migrate-db.sh
./scripts/04-cutover-check.sh
```

## Cost

EKS control plane (~$0.10/h) + 2× t3.small + RDS t4g.micro + NLB ≈ **$0.25–0.30/h**.
Run it in a session, then `terraform destroy`. Never leave it up overnight by accident:
`scripts/05-destroy.sh` tears down everything, including the ArgoCD-created NLB.

## Stretch goals (what "beyond a standard migration" looks like)

1. Replace the managed node group with **Karpenter**.
2. Replace `Service: LoadBalancer` with the **AWS Load Balancer Controller** + ALB + ACM cert.
3. Pull DB credentials from **Secrets Manager** with **External Secrets Operator** instead of a kubectl-created Secret.
4. Add **kube-prometheus-stack** and a Grafana dashboard for the app.
5. Add an ArgoCD **ApplicationSet** for dev/prod overlays with Kustomize.
6. Do the DB migration with **AWS DMS** for near-zero downtime instead of dump/restore.
