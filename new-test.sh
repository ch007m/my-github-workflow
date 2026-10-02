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

# Close test PR
echo "Cleaning up test PR and branches..."
gh pr list --repo "$(gh repo view --json nameWithOwner --jq '.nameWithOwner')" \
  --state open --json number,headRefName \
  --jq '.[] | select(.headRefName | startswith("test/")) | "\(.number) \(.headRefName)"' \
| while read -r pr_number branch_name; do
    echo "  Closing PR #$pr_number ($branch_name)"
    gh pr close "$pr_number" --delete-branch 2>/dev/null || true
  done

# Delete test branch locally and remotely
git checkout main
git branch -D "$BRANCH" 2>/dev/null || true
git push origin --delete "$BRANCH" 2>/dev/null || true
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
PR_NUMBER=$(echo "$PR_URL" | grep -o '[0-9]*$')
REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')

echo ""
echo "==========================================="
echo "PR created: $PR_URL"
echo "==========================================="

# Show initial status
echo ""
echo "--- Initial PR status (before label) ---"
echo "Labels: $(gh pr view "$PR_NUMBER" --json labels --jq '[.labels[].name] | join(", ") // "none"')"
echo "Mergeable: $(gh pr view "$PR_NUMBER" --json mergeable --jq '.mergeable')"
echo ""
echo "Checks:"
gh pr checks "$PR_NUMBER" --repo "$REPO" 2>/dev/null || echo "  No checks reported yet"

# Wait for checks to appear
echo ""
echo "Waiting 15s for initial checks to run..."
sleep 15

echo ""
echo "--- PR status (before label, after initial checks) ---"
echo "Checks:"
gh pr checks "$PR_NUMBER" --repo "$REPO" 2>/dev/null || echo "  No checks reported yet"

# Show commit statuses
SHA=$(gh pr view "$PR_NUMBER" --json headRefOid --jq '.headRefOid')
echo ""
echo "Commit statuses:"
gh api "repos/$REPO/commits/$SHA/status" --jq '.statuses[] | "  \(.context): \(.state) - \(.description)"' 2>/dev/null || echo "  None"

# Prompt to apply label
echo ""
echo "==========================================="
echo "To apply the label, run:"
echo "  gh pr edit $PR_NUMBER --add-label \"status: to-test\""
echo "==========================================="
echo ""
read -p "Press ENTER after applying the label to continue monitoring..." _

# Show status after label
echo ""
echo "--- PR status (after label) ---"
echo "Labels: $(gh pr view "$PR_NUMBER" --json labels --jq '[.labels[].name] | join(", ") // "none"')"

echo ""
echo "Waiting for workflows to start..."
sleep 10

# Poll checks until they complete (max 2 minutes)
for i in $(seq 1 12); do
  echo ""
  echo "--- Check status (attempt $i/12) ---"
  gh pr checks "$PR_NUMBER" --repo "$REPO" 2>/dev/null || echo "  No checks reported yet"

  echo ""
  echo "Commit statuses:"
  gh api "repos/$REPO/commits/$SHA/status" --jq '.statuses[] | "  \(.context): \(.state) - \(.description)"' 2>/dev/null || echo "  None"

  # Stop polling if all checks are done
  PENDING=$(gh pr checks "$PR_NUMBER" --repo "$REPO" 2>/dev/null | grep -c "pending\|running" || true)
  if [ "$PENDING" -eq 0 ] 2>/dev/null; then
    echo ""
    echo "All checks completed!"
    break
  fi

  echo "Waiting 10s..."
  sleep 10
done

echo ""
echo "--- Final PR status ---"
echo "Labels: $(gh pr view "$PR_NUMBER" --json labels --jq '[.labels[].name] | join(", ")')"
echo "Mergeable: $(gh pr view "$PR_NUMBER" --json mergeable --jq '.mergeable')"
echo ""
echo "Checks:"
gh pr checks "$PR_NUMBER" --repo "$REPO" 2>/dev/null
echo ""
echo "Commit statuses:"
gh api "repos/$REPO/commits/$SHA/status" --jq '.statuses[] | "  \(.context): \(.state) - \(.description)"' 2>/dev/null || echo "  None"

git checkout main
