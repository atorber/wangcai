#!/usr/bin/env bash
# Sync root VERSION into pubspec.yaml (Flutter still needs a version field at build time).
# Source of truth: ./VERSION  (e.g. 0.2.2+3)
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_FILE="${ROOT_DIR}/VERSION"
PUBSPEC_FILE="${ROOT_DIR}/pubspec.yaml"

if [[ ! -f "${VERSION_FILE}" ]]; then
  echo "VERSION file not found: ${VERSION_FILE}" >&2
  exit 1
fi

VERSION="$(tr -d '[:space:]' < "${VERSION_FILE}")"
if [[ ! "${VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+(\+[0-9]+)?$ ]]; then
  echo "Invalid VERSION format: '${VERSION}' (expected like 0.2.2+3)" >&2
  exit 1
fi

if [[ ! -f "${PUBSPEC_FILE}" ]]; then
  echo "pubspec.yaml not found: ${PUBSPEC_FILE}" >&2
  exit 1
fi

if grep -qE '^version:' "${PUBSPEC_FILE}"; then
  # portable in-place replace without relying on GNU sed -i
  TMP_FILE="$(mktemp)"
  awk -v ver="${VERSION}" '
    BEGIN { done = 0 }
    /^version:/ && !done {
      print "version: " ver
      done = 1
      next
    }
    { print }
  ' "${PUBSPEC_FILE}" > "${TMP_FILE}"
  mv "${TMP_FILE}" "${PUBSPEC_FILE}"
else
  echo "No version: field found in pubspec.yaml" >&2
  exit 1
fi

echo "Synced VERSION ${VERSION} -> pubspec.yaml"
