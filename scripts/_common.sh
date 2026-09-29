set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
if [[ ! -f "$HERE/env.sh" ]]; then echo "Copy scripts/env.example.sh to scripts/env.sh and edit it." >&2; exit 1; fi
# shellcheck source=/dev/null
source "$HERE/env.sh"
tfout() { terraform -chdir="$ROOT/terraform" output -raw "$1"; }
log() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
