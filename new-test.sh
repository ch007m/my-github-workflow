#!/bin/bash
set -euo pipefail

if [ -z "${1:-}" ]; then
  echo "Usage: $0 <test-number>"
  echo "Example: $0 007"
  exit 1
fi

VALUE="$1"
BRANCH="test/${VALUE}-test"

# Close previous test PRs and delete their branches
echo "Cleaning up previous test PRs and branches..."
gh pr list --repo "$(gh repo view --json nameWithOwner --jq '.nameWithOwner')" \
  --state open --json number,headRefName \
  --jq '.[] | select(.headRefName | startswith("test/")) | "\(.number) \(.headRefName)"' \
| while read -r pr_number branch_name; do
    echo "  Closing PR #$pr_number ($branch_name)"
    gh pr close "$pr_number" --delete-branch 2>/dev/null || true
  done

git checkout main
git pull origin main
git checkout -b "$BRANCH"

sed -i '' "s/^- Max [0-9]* messages/- Max $VALUE messages/" skills/hello/SKILL.md

git add skills/hello/SKILL.md
git commit -m "Test $VALUE"
git push -u origin "$BRANCH"

PR_URL=$(gh pr create --title "Test $VALUE" --body "Test $VALUE" 2>&1)
echo ""
echo "PR created: $PR_URL"

git checkout main
