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

show_status() {
  local label="$1"
  local pr="$2"
  local repo="$3"
  local sha="$4"

  echo ""
  echo "==========================================="
  echo " $label"
  echo "==========================================="

  echo ""
  echo "Labels: $(gh pr view "$pr" --json labels --jq '[.labels[].name] | join(", ") // "none"')"
  echo "Mergeable: $(gh pr view "$pr" --json mergeable --jq '.mergeable')"

  echo ""
  echo "Workflow runs:"
  gh api "repos/$repo/actions/runs?head_sha=$sha" \
    --jq '.workflow_runs[] | "  #\(.run_number) \(.name) [\(.status)/\(.conclusion // "—")] \(.html_url)"' \
    2>/dev/null || echo "  None"

  echo ""
  echo "Jobs:"
  gh pr checks "$pr" --repo "$repo" 2>/dev/null || echo "  No checks reported yet"

  echo ""
  echo "Commit statuses:"
  gh api "repos/$repo/commits/$sha/status" \
    --jq '.statuses[] | "  \(.context): \(.state) — \(.description)"' \
    2>/dev/null || echo "  None"
}

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
SHA=$(gh pr view "$PR_NUMBER" --json headRefOid --jq '.headRefOid')

echo ""
echo "PR created: $PR_URL"

echo ""
echo "Waiting 15s for initial checks..."
sleep 15

show_status "BEFORE LABEL" "$PR_NUMBER" "$REPO" "$SHA"

# Prompt to apply label
echo ""
echo "==========================================="
echo "To apply the label, run:"
echo "  gh pr edit $PR_NUMBER --add-label \"status: to-test\""
echo "==========================================="
echo ""
read -p "Press ENTER after applying the label to continue monitoring..." _

echo ""
echo "Waiting 10s for workflows to start..."
sleep 10

# Poll until all checks complete (max 3 minutes)
for i in $(seq 1 18); do
  show_status "AFTER LABEL (poll $i/18)" "$PR_NUMBER" "$REPO" "$SHA"

  PENDING=$(gh pr checks "$PR_NUMBER" --repo "$REPO" 2>/dev/null | grep -c "pending\|running" || true)
  PENDING_STATUS=$(gh api "repos/$REPO/commits/$SHA/status" --jq '[.statuses[] | select(.state=="pending")] | length' 2>/dev/null || echo "0")

  if [ "$PENDING" -eq 0 ] && [ "$PENDING_STATUS" -eq 0 ] 2>/dev/null; then
    echo ""
    echo "All checks and statuses completed!"
    break
  fi

  echo ""
  echo "Waiting 10s..."
  sleep 10
done

show_status "FINAL STATUS" "$PR_NUMBER" "$REPO" "$SHA"

git checkout main
