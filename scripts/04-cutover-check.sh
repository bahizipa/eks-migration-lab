#!/usr/bin/env bash
# Phase 5 — verify the AWS side before switching traffic (DNS / clients).
source "$(dirname "$0")/_common.sh"

log "Wait for the NLB hostname"
for _ in $(seq 1 30); do
  LB="$(kubectl -n notes get svc notes-api -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)"
  [[ -n "$LB" ]] && break; sleep 10
done
[[ -n "$LB" ]] || { echo "No load balancer yet"; exit 1; }
echo "AWS endpoint: http://$LB"

log "Wait for DNS + targets (NLB can take ~3 min)"
until curl -fsS "http://$LB/health" >/dev/null 2>&1; do sleep 10; printf .; done; echo

log "Compare legacy vs AWS"
echo "legacy: $(curl -fsS "$LEGACY_API_URL/notes/count")"
echo "aws:    $(curl -fsS "http://$LB/notes/count")"
curl -fsS "http://$LB/health"; echo

log "Write test on AWS (post-cutover writes must land in RDS only)"
curl -fsS -X POST "http://$LB/notes" -H 'content-type: application/json' \
  -d '{"title":"cutover-test","body":"written on EKS"}'; echo

cat <<MSG

Cutover checklist:
  [ ] counts matched before the write test
  [ ] /health reports env=aws-eks
  [ ] point DNS (or clients) at http://$LB
  [ ] set legacy API read-only / stop it: cd legacy && docker compose stop api
  [ ] keep legacy DB volume for the rollback window, then delete it
MSG
