#!/usr/bin/env bash
# Phase 3 — install ArgoCD and register the notes-api Application.
source "$(dirname "$0")/_common.sh"

aws eks update-kubeconfig --region "$AWS_REGION" --name "$(tfout cluster_name)" >/dev/null

log "Install ArgoCD"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd rollout status deploy/argocd-server --timeout=300s

log "Register Application pointing at $GITOPS_REPO_URL"
sed "s#REPLACE_WITH_GITOPS_REPO_URL#$GITOPS_REPO_URL#" "$ROOT/gitops/argocd/notes-api-app.yaml" | kubectl apply -f -

log "ArgoCD admin password (UI: kubectl -n argocd port-forward svc/argocd-server 8443:443)"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
echo "Note: the app will stay Degraded until 03-migrate-db.sh creates the notes-db secret."
