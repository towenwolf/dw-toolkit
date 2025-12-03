#!/usr/bin/env bash
set -euo pipefail

# Usage: ./prune-local-branches.sh [remote-name]
# Default remote is "origin"
REMOTE="${1:-origin}"

# Branches you never want deleted automatically
PROTECTED_BRANCHES=("main" "master" "develop")

is_protected() {
  local b="$1"
  for p in "${PROTECTED_BRANCHES[@]}"; do
    if [[ "$b" == "$p" ]]; then
      return 0
    fi
  done
  return 1
}

# Must be run inside a git repo
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "Error: not inside a git repository." >&2
  exit 1
fi

# Make sure remote exists
if ! git remote | grep -qx "$REMOTE"; then
  echo "Error: remote '$REMOTE' not found." >&2
  exit 1
fi

# Update remote-tracking branches and prune deleted ones
git fetch --prune "$REMOTE"

CURRENT_BRANCH="$(git symbolic-ref --short HEAD)"

# Loop over all local branches
git for-each-ref --format='%(refname:short)' refs/heads/ | while read -r BRANCH; do
  # Skip current branch and protected branches
  if [[ "$BRANCH" == "$CURRENT_BRANCH" ]] || is_protected "$BRANCH"; then
    continue
  fi

  # If there is no corresponding remote branch, delete the local one
  if ! git show-ref --verify --quiet "refs/remotes/$REMOTE/$BRANCH"; then
    echo "Deleting local branch '$BRANCH' (no '$REMOTE/$BRANCH')"
    git branch -D "$BRANCH"
  fi
done
