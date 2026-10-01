#!/bin/bash
set -euo pipefail

if [ -z "${1:-}" ]; then
  echo "Usage: $0 <test-number>"
  echo "Example: $0 007"
  exit 1
fi

VALUE="$1"
BRANCH="test/${VALUE}-test"

git checkout main
git pull origin main
git checkout -b "$BRANCH"

sed -i '' "s/Test [0-9]*/Test $VALUE/" README.md

git add README.md
git commit -m "Test $VALUE"
git push -u origin "$BRANCH"

PR_URL=$(gh pr create --title "Test $VALUE" --body "Test $VALUE" 2>&1)
echo ""
echo "PR created: $PR_URL"
