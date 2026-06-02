#!/usr/bin/env bash
#
# Unified test runner.
#
# Detects the project type (React or NestJS/Node.js) from package.json,
# cleans previous artifacts, ensures dependencies are installed, runs the
# test suite (which produces a JUnit XML report in test-results/), and
# propagates the test exit code.
#
# Usage: ./run-tests.sh

set -euo pipefail

# Work from the directory containing this script, so it can be invoked
# from anywhere (CI, repo root, etc.).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

RESULTS_DIR="test-results"

if [ ! -f package.json ]; then
  echo "Error: no package.json found in $SCRIPT_DIR" >&2
  exit 1
fi

# --- 1. Detect the project type from package.json dependencies ---
detect_project_type() {
  node -e '
    const pkg = require("./package.json");
    const deps = { ...(pkg.dependencies || {}), ...(pkg.devDependencies || {}) };
    if (deps["react"]) { console.log("react"); }
    else if (deps["@nestjs/core"]) { console.log("nestjs"); }
    else { console.log("unknown"); }
  '
}

PROJECT_TYPE="$(detect_project_type)"

case "$PROJECT_TYPE" in
  react)  echo "Detected project type: React frontend" ;;
  nestjs) echo "Detected project type: NestJS backend" ;;
  *)
    echo "Error: unsupported project type (expected React or NestJS)" >&2
    exit 1
    ;;
esac

# --- 2. Clean previous test artifacts ---
echo "Cleaning previous test artifacts in $RESULTS_DIR/ ..."
rm -rf "$RESULTS_DIR"
mkdir -p "$RESULTS_DIR"

# --- 3. Ensure dependencies are installed ---
if [ ! -d node_modules ]; then
  echo "node_modules not found, installing dependencies with npm ci ..."
  npm ci
fi

# --- 4. Run the test suite (produces JUnit XML via jest-junit) ---
# Capture the exit code without tripping `set -e` when tests fail.
echo "Running tests ..."
TEST_EXIT_CODE=0
npm test || TEST_EXIT_CODE=$?

# --- 5. Report and propagate the exit code ---
if [ "$TEST_EXIT_CODE" -eq 0 ]; then
  echo "Tests passed. JUnit report: $RESULTS_DIR/junit.xml"
else
  echo "Tests failed (exit code $TEST_EXIT_CODE)." >&2
fi

exit "$TEST_EXIT_CODE"
