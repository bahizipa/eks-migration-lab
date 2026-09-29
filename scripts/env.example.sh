# Copy to env.sh and edit. env.sh is gitignored.
export AWS_REGION="eu-west-1"
export PROJECT="notes-lab"
export GITOPS_REPO_URL="https://github.com/YOUR_USER/eks-migration-lab.git"
export IMAGE_TAG="v1"
# Legacy ("OVH") side — where the old stack is reachable from this machine
export LEGACY_API_URL="http://localhost:8080"
export LEGACY_DATABASE_URL="postgresql://notes:notes@localhost:5432/notes"
