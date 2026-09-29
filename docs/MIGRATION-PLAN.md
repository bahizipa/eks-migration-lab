# Migration plan — the story you can tell in the interview

Treat the lab as a rehearsal. For each phase, note what you'd change at enterprise scale.

## 0. Discovery (legacy)
- Inventory: services, ports, data stores, secrets, cron jobs, outbound dependencies.
- Capture runtime facts: image sizes, resource usage, DB size, peak RPS.
- Decide per service: rehost (lift container as-is) vs replatform (managed DB, queues) vs refactor.
- Lab: `notes-api` = rehost, Postgres = replatform to RDS.

## 1. Landing zone
- VPC with public / private / database subnets across 2 AZ, NAT, correct EKS subnet tags.
- EKS with access entries (no aws-auth ConfigMap edits), managed node group, core addons.
- RDS in isolated subnets, SG that only accepts the node SG. Credentials in Secrets Manager.
- **Enterprise:** you would *not* create this — the central platform team owns it. Your job is
  to understand their landing zone (account structure, IPAM, egress, IAM boundaries, allowed
  EKS patterns, ingress standard, secrets standard) and fit the workload into it.

## 2. Containerise & registry
- Non-root, read-only FS, pinned deps, scan on push.
- **Enterprise:** central registry, image signing/verification (cosign + Kyverno), SBOMs.

## 3. GitOps
- ArgoCD Application per workload, auto-sync + prune + self-heal, finalizer so cleanup is real.
- **Enterprise:** app-of-apps or ApplicationSets, environment overlays, RBAC projects,
  ArgoCD notifications, image updater.

## 4. Data migration
- Lab: freeze ➜ pg_dump ➜ restore ➜ row-count check. Simple, needs downtime.
- **Enterprise:** AWS DMS or logical replication for continuous sync, then short cutover;
  checksum tables, not just counts; rehearse twice before the real window.

## 5. Cutover
- Verify health, data parity, a write test; then lower DNS TTL in advance, switch, watch.
- Rollback plan written *before* cutover: what is the trigger, who decides, how long the
  legacy DB stays writable-frozen.

## 6. Decommission
- Keep legacy read-only for the rollback window, then delete. Close OVH billing items.
- Update runbooks, monitoring, on-call.

## Questions this lab prepares you to ask Clearnox / CodaBox
1. What does the central AWS platform give us out of the box (EKS baseline, ingress, secrets, observability), and where are the gaps?
2. Which OVH services are stateful, and what's the accepted downtime per service?
3. Is there a GitOps standard already (ArgoCD? Flux?) and a repo layout convention?
4. Who owns DNS and TLS for the cutover?
5. What has already been migrated, what blocked it, and what's the rollback story?
