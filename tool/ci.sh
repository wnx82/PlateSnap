#!/usr/bin/env bash
# Simple local CI pipeline for PlateSnap: fetch deps, static analysis, tests.
# Stops at the first failing step (set -e).
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> flutter pub get"
flutter pub get

echo "==> flutter analyze"
flutter analyze

echo "==> flutter test"
flutter test

echo "==> All checks passed."
