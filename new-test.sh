#!/bin/bash
set -euo pipefail

if [ -z "${1:-}" ] || [ -z "${2:-}" ]; then
  echo "Usage: $0 <test-number> <skill|readme>"
  echo "Example: $0 007 skill"
  echo "         $0 007 readme"
  exit 1
fi

VALUE="$1"
TARGET="$2"
BRANCH="test/${VALUE}"

# Close test PR and delete the branch
echo "Cleaning up test PR and branche..."
gh pr list --repo "$(gh repo view --json nameWithOwner --jq '.nameWithOwner')" \
  --state open --json number,headRefName \
  --jq '.[] | select(.headRefName | startswith("test/")) | "\(.number) \(.headRefName)"' \
| while read -r pr_number branch_name; do
    echo "  Closing PR #$pr_number ($branch_name)"
    gh pr close "$pr_number" --delete-branch 2>/dev/null || true
    git delete branch -D $BRANCH
  done

git checkout main
git pull origin main
git checkout -b "$BRANCH"

case "$TARGET" in
  skill)
    sed -i '' "s/^- Max [0-9]* messages/- Max $VALUE messages/" skills/hello/SKILL.md
    git add skills/hello/SKILL.md
    ;;
  readme)
    sed -i '' "s/Test [0-9]*/Test $VALUE/" README.md
    git add README.md
    ;;
  *)
    echo "Error: second argument must be 'skill' or 'readme'"
    exit 1
    ;;
esac

git commit -m "Test $VALUE"
git push -u origin "$BRANCH"

PR_URL=$(gh pr create --title "Test $VALUE" --body "Test $VALUE" 2>&1)
echo ""
echo "PR created: $PR_URL"

git checkout main
