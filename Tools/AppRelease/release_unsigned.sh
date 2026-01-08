#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT="${ROOT_DIR}/Invar.xcodeproj"
SCHEME="Invar"
APP_NAME="Invar"
RELEASE_ROOT="${ROOT_DIR}/Tools/AppRelease"
BUILD_DIR="${RELEASE_ROOT}/build"
DERIVED_DATA="${BUILD_DIR}/DerivedData"
DIST_DIR="${RELEASE_ROOT}/dist"
DMG_STAGE="${BUILD_DIR}/dmg"

VERSION_OVERRIDE="${1:-}"
if [[ -n "${VERSION_OVERRIDE}" ]]; then
  VERSION="${VERSION_OVERRIDE}"
else
  build_settings=$(xcodebuild -project "${PROJECT}" -scheme "${SCHEME}" -configuration Release -showBuildSettings 2>/dev/null)
  MARKETING_VERSION=$(echo "${build_settings}" | awk -F' = ' '/MARKETING_VERSION/ {print $2; exit}')
  CURRENT_PROJECT_VERSION=$(echo "${build_settings}" | awk -F' = ' '/CURRENT_PROJECT_VERSION/ {print $2; exit}')

  if [[ -z "${MARKETING_VERSION}" ]]; then
    MARKETING_VERSION="0.0.0"
  fi
  if [[ -z "${CURRENT_PROJECT_VERSION}" ]]; then
    CURRENT_PROJECT_VERSION="0"
  fi

  VERSION="${MARKETING_VERSION}(${CURRENT_PROJECT_VERSION})"
fi

rm -rf "${DERIVED_DATA}" "${DIST_DIR}" "${DMG_STAGE}"
mkdir -p "${DIST_DIR}" "${BUILD_DIR}"

xcodebuild \
  -project "${PROJECT}" \
  -scheme "${SCHEME}" \
  -configuration Release \
  -derivedDataPath "${DERIVED_DATA}" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build

APP_PATH="${DERIVED_DATA}/Build/Products/Release/${APP_NAME}.app"
if [[ ! -d "${APP_PATH}" ]]; then
  echo "Built app not found at ${APP_PATH}" >&2
  exit 1
fi

cp -R "${APP_PATH}" "${DIST_DIR}/${APP_NAME}.app"

ditto -c -k --sequesterRsrc --keepParent "${DIST_DIR}/${APP_NAME}.app" "${DIST_DIR}/${APP_NAME}-${VERSION}-macos-unsigned.zip"

mkdir -p "${DMG_STAGE}"
cp -R "${DIST_DIR}/${APP_NAME}.app" "${DMG_STAGE}/${APP_NAME}.app"
ln -s /Applications "${DMG_STAGE}/Applications"

if hdiutil create \
  -volname "${APP_NAME}" \
  -srcfolder "${DMG_STAGE}" \
  -ov -format UDZO \
  "${DIST_DIR}/${APP_NAME}-${VERSION}-macos-unsigned.dmg"; then
  echo "DMG created."
else
  echo "Warning: DMG creation failed. ZIP output is still available." >&2
  echo "If you see \"Device not configured\", rerun outside a sandboxed environment." >&2
  rm -f "${DIST_DIR}/${APP_NAME}-${VERSION}-macos-unsigned.dmg"
fi

rm -rf "${DMG_STAGE}"

echo "Unsigned artifacts created:"
echo "- ${DIST_DIR}/${APP_NAME}.app"
echo "- ${DIST_DIR}/${APP_NAME}-${VERSION}-macos-unsigned.zip"
if [[ -f "${DIST_DIR}/${APP_NAME}-${VERSION}-macos-unsigned.dmg" ]]; then
  echo "- ${DIST_DIR}/${APP_NAME}-${VERSION}-macos-unsigned.dmg"
fi
