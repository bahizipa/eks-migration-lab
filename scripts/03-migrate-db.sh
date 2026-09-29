#!/usr/bin/env bash
# Phase 4 — move the data: dump legacy Postgres, restore into RDS, create the K8s secret.
# Runs psql from a throwaway pod inside the cluster, because RDS is private.
source "$(dirname "$0")/_common.sh"

DUMP="/tmp/notes-$(date +%Y%m%d-%H%M%S).sql"
log "Freeze writes on legacy (real life: maintenance window / read-only flag), then dump"
pg_dump --no-owner --no-privileges "$LEGACY_DATABASE_URL" > "$DUMP"
echo "dump: $DUMP ($(wc -l < "$DUMP") lines)"

log "Read target credentials from Secrets Manager"
SECRET_JSON="$(aws secretsmanager get-secret-value --region "$AWS_REGION" --secret-id "$(tfout db_secret_name)" --query SecretString --output text)"
TARGET_URL="$(echo "$SECRET_JSON" | python3 -c 'import sys,json;print(json.load(sys.stdin)["DATABASE_URL"])')"

log "Create notes-db secret for the app"
kubectl create namespace notes --dry-run=client -o yaml | kubectl apply -f -
kubectl -n notes create secret generic notes-db --from-literal=DATABASE_URL="$TARGET_URL" \
  --dry-run=client -o yaml | kubectl apply -f -

log "Restore into RDS via an in-cluster psql pod"
kubectl -n notes delete pod pg-restore --ignore-not-found >/dev/null
kubectl -n notes run pg-restore --image=postgres:16-alpine --restart=Never --command -- sleep 600 >/dev/null
kubectl -n notes wait --for=condition=Ready pod/pg-restore --timeout=120s
kubectl -n notes cp "$DUMP" pg-restore:/tmp/dump.sql
kubectl -n notes exec pg-restore -- sh -c "psql '$TARGET_URL' -v ON_ERROR_STOP=1 -q -f /tmp/dump.sql"

log "Row count check"
SRC=$(psql "$LEGACY_DATABASE_URL" -tAc 'select count(*) from notes')
DST=$(kubectl -n notes exec pg-restore -- psql "$TARGET_URL" -tAc 'select count(*) from notes')
echo "legacy=$SRC  rds=$DST"
[[ "$SRC" == "$DST" ]] && echo "OK: counts match" || { echo "MISMATCH"; exit 1; }
kubectl -n notes delete pod pg-restore >/dev/null
