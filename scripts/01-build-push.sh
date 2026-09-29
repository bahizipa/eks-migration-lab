#!/usr/bin/env bash
# Phase 2 — containerise & push to ECR, then pin the image in the GitOps repo.
source "$(dirname "$0")/_common.sh"

ECR_URL="$(tfout ecr_repository_url)"
REGISTRY="${ECR_URL%%/*}"

log "Login to ECR $REGISTRY"
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$REGISTRY"

log "Build & push $ECR_URL:$IMAGE_TAG (linux/amd64 for t3 nodes)"
docker build --platform linux/amd64 -t "$ECR_URL:$IMAGE_TAG" "$ROOT/legacy/app"
docker push "$ECR_URL:$IMAGE_TAG"

log "Pin image in gitops/apps/notes-api/kustomization.yaml"
cd "$ROOT/gitops/apps/notes-api"
kustomize edit set image "notes-api=$ECR_URL:$IMAGE_TAG" 2>/dev/null \
  || sed -i.bak -e "s#newName: .*#newName: $ECR_URL#" -e "s#newTag: .*#newTag: $IMAGE_TAG#" kustomization.yaml
rm -f kustomization.yaml.bak

log "Commit and push so ArgoCD can pick it up"
cd "$ROOT" && git add gitops && git commit -m "notes-api: image $IMAGE_TAG" && git push
