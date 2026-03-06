#!/usr/bin/env bash
# Test script for the no-direct-commits-to-main pre-commit hook.
# This script verifies the hook logic in three scenarios:
#   1. On main branch -> hook should exit 1 with error message
#   2. On a feature branch -> hook should exit 0
#   3. In detached HEAD state -> hook should exit 0
#
# Usage: ./scripts/test-no-direct-commits-hook.sh
#
# The hook logic under test (extracted from .pre-commit-config.yaml entry):
#   BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null)
#   if [ "$BRANCH" = "main" ]; then
#     echo "ERROR: Direct commits to main are not allowed. Please create a feature branch."
#     exit 1
#   fi

set -euo pipefail

PASS=0
FAIL=0
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

pass() {
  PASS=$((PASS + 1))
  echo -e "${GREEN}PASS${NC}: $1"
}

fail() {
  FAIL=$((FAIL + 1))
  echo -e "${RED}FAIL${NC}: $1"
}

# Extract the hook entry script from .pre-commit-config.yaml
# The entry field contains the inline bash script for the hook.
# We look for the entry under id: no-direct-commits-to-main
extract_hook_script() {
  local config_file="$REPO_DIR/.pre-commit-config.yaml"
  if [ ! -f "$config_file" ]; then
    echo "ERROR: .pre-commit-config.yaml not found at $config_file"
    return 1
  fi

  # Extract the entry field value for no-direct-commits-to-main hook
  # The entry is a bash -c '...' command; we need the inner script
  local entry
  entry=$(python3 -c "
import yaml, sys
with open('$config_file') as f:
    config = yaml.safe_load(f)
for repo in config.get('repos', []):
    for hook in repo.get('hooks', []):
        if hook.get('id') == 'no-direct-commits-to-main':
            print(hook.get('entry', ''))
            sys.exit(0)
print('')
sys.exit(1)
" 2>/dev/null) || true

  if [ -z "$entry" ]; then
    echo "ERROR: Could not find no-direct-commits-to-main hook entry in .pre-commit-config.yaml"
    return 1
  fi

  echo "$entry"
}

# Create a temporary git repo for isolated testing
setup_test_repo() {
  local tmpdir
  tmpdir=$(mktemp -d)
  cd "$tmpdir"
  git init -b main --quiet
  git config user.email "test@test.com"
  git config user.name "Test"
  echo "initial" > file.txt
  git add file.txt
  git commit -m "initial commit" --quiet
  echo "$tmpdir"
}

cleanup_test_repo() {
  local tmpdir="$1"
  rm -rf "$tmpdir"
}

echo "============================================"
echo "Testing no-direct-commits-to-main hook"
echo "============================================"
echo ""

# Step 1: Verify hook exists in config
echo "--- Prerequisite: Hook exists in .pre-commit-config.yaml ---"
HOOK_SCRIPT=""
if extract_hook_result=$(extract_hook_script 2>&1); then
  HOOK_SCRIPT="$extract_hook_result"
fi
if [ -z "$HOOK_SCRIPT" ] || echo "$HOOK_SCRIPT" | grep -q "^ERROR:"; then
  fail "Hook entry not found in .pre-commit-config.yaml"
  echo ""
  echo "Results: $PASS passed, $FAIL failed"
  exit 1
fi
pass "Hook entry found in .pre-commit-config.yaml"
echo "  Entry: $HOOK_SCRIPT"
echo ""

# Step 2: Verify hook config fields
echo "--- Prerequisite: Hook configuration fields ---"
CONFIG_FILE="$REPO_DIR/.pre-commit-config.yaml"
HOOK_CONFIG=$(python3 -c "
import yaml, json
with open('$CONFIG_FILE') as f:
    config = yaml.safe_load(f)
for repo in config.get('repos', []):
    for hook in repo.get('hooks', []):
        if hook.get('id') == 'no-direct-commits-to-main':
            print(json.dumps(hook))
")

check_field() {
  local field="$1"
  local expected="$2"
  local actual
  actual=$(echo "$HOOK_CONFIG" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('$field',''))")
  if [ "$actual" = "$expected" ]; then
    pass "Hook field '$field' = '$expected'"
  else
    fail "Hook field '$field' expected '$expected', got '$actual'"
  fi
}

check_field "id" "no-direct-commits-to-main"
check_field "language" "system"
check_field "always_run" "True"
check_field "pass_filenames" "False"
echo ""

# Test 1: Hook blocks commits on main branch
echo "--- Test 1: Hook blocks commits on main branch ---"
TMPDIR=$(setup_test_repo)
cd "$TMPDIR"
# We are on main branch
CURRENT=$(git symbolic-ref --short HEAD 2>/dev/null)
if [ "$CURRENT" != "main" ]; then
  fail "Test setup: expected to be on main, but on '$CURRENT'"
else
  # Run the hook script
  set +e
  OUTPUT=$(eval "$HOOK_SCRIPT" 2>&1)
  EXIT_CODE=$?
  set -e

  if [ "$EXIT_CODE" -ne 0 ]; then
    pass "Hook exits non-zero ($EXIT_CODE) on main branch"
  else
    fail "Hook should exit non-zero on main, but exited $EXIT_CODE"
  fi

  if echo "$OUTPUT" | grep -qi "error.*direct commits.*main.*not allowed"; then
    pass "Hook displays error message about direct commits to main"
  else
    fail "Hook error message missing or incorrect. Output: '$OUTPUT'"
  fi
fi
cleanup_test_repo "$TMPDIR"
echo ""

# Test 2: Hook allows commits on feature branches
echo "--- Test 2: Hook allows commits on feature branches ---"
TMPDIR=$(setup_test_repo)
cd "$TMPDIR"
git checkout -b feature/test-branch --quiet
CURRENT=$(git symbolic-ref --short HEAD 2>/dev/null)
if [ "$CURRENT" != "feature/test-branch" ]; then
  fail "Test setup: expected to be on feature/test-branch, but on '$CURRENT'"
else
  set +e
  OUTPUT=$(eval "$HOOK_SCRIPT" 2>&1)
  EXIT_CODE=$?
  set -e

  if [ "$EXIT_CODE" -eq 0 ]; then
    pass "Hook exits 0 on feature branch"
  else
    fail "Hook should exit 0 on feature branch, but exited $EXIT_CODE"
  fi

  if [ -z "$OUTPUT" ]; then
    pass "Hook produces no error output on feature branch"
  else
    fail "Hook should produce no output on feature branch. Output: '$OUTPUT'"
  fi
fi
cleanup_test_repo "$TMPDIR"
echo ""

# Test 3: Hook handles detached HEAD gracefully
echo "--- Test 3: Hook handles detached HEAD state ---"
TMPDIR=$(setup_test_repo)
cd "$TMPDIR"
COMMIT_HASH=$(git rev-parse HEAD)
git checkout "$COMMIT_HASH" --quiet 2>/dev/null
SYMBOLIC_REF=$(git symbolic-ref --short HEAD 2>/dev/null || echo "")
if [ -n "$SYMBOLIC_REF" ]; then
  fail "Test setup: expected detached HEAD, but symbolic-ref returned '$SYMBOLIC_REF'"
else
  set +e
  OUTPUT=$(eval "$HOOK_SCRIPT" 2>&1)
  EXIT_CODE=$?
  set -e

  if [ "$EXIT_CODE" -eq 0 ]; then
    pass "Hook exits 0 in detached HEAD state"
  else
    fail "Hook should exit 0 in detached HEAD, but exited $EXIT_CODE"
  fi

  if [ -z "$OUTPUT" ]; then
    pass "Hook produces no error output in detached HEAD"
  else
    fail "Hook should produce no output in detached HEAD. Output: '$OUTPUT'"
  fi
fi
cleanup_test_repo "$TMPDIR"
echo ""

# Summary
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
