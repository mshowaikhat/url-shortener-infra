#!/usr/bin/env bash
# Demo-grade `terraform destroy` orchestration.
#
# Two resource classes need special handling before destroy:
#
#   1. Firestore database — has `prevent_destroy = true` because it stores
#      the canonical URL data and Firestore re-enablement is blocked for
#      DAYS after a delete. We `state rm` it before destroy and re-import
#      on restore. The database itself stays in GCP.
#
#   2. Workload Identity Pool + Provider — soft-deleted by GCP for 30 days
#      after destroy. Recreating with the same pool/provider IDs during
#      that window can fail or attach to the soft-deleted shell. We `state
#      rm` so destroy leaves them alone, and we re-import on restore.

set -euo pipefail

PROTECTED_RESOURCES=(
  "module.firestore.google_firestore_database.default"
  "module.workload_identity.google_iam_workload_identity_pool.github"
  "module.workload_identity.google_iam_workload_identity_pool_provider.github"
)

echo "==> Step 1/2: state rm protected resources"
for addr in "${PROTECTED_RESOURCES[@]}"; do
  if terraform state list "$addr" >/dev/null 2>&1; then
    terraform state rm "$addr"
    echo "    -> removed $addr"
  else
    echo "    -> $addr not in state (skip)"
  fi
done

echo ""
echo "==> Step 2/2: terraform destroy"
terraform destroy -auto-approve

echo ""
echo "DESTROY COMPLETE."
echo ""
echo "Firestore DB and WIF pool/provider survive in GCP and will be"
echo "re-imported into state by 'make restore'."
