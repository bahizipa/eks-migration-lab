#!/usr/bin/env bash
# Tear everything down. Delete the ArgoCD app first so the NLB it created disappears,
# otherwise terraform destroy hangs on the VPC.
source "$(dirname "$0")/_common.sh"
log "Delete ArgoCD Application (removes Service/NLB)"
kubectl -n argocd delete application notes-api --ignore-not-found --timeout=180s || true
kubectl -n notes delete svc notes-api --ignore-not-found || true
sleep 30
log "terraform destroy"
terraform -chdir="$ROOT/terraform" destroy -auto-approve
