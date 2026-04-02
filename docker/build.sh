#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# THOTH — Docker Build Script
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

IMAGE_NAME="${1:-thoth}"
TAG="${2:-latest}"
GPU_TARGETS="${GPU_TARGETS:-gfx1030}"
BUILD_JOBS="${THOTH_BUILD_JOBS:-${BUILD_JOBS:-8}}"

"$SCRIPT_DIR/preflight.sh" /

echo "╔══════════════════════════════════════════════╗"
echo "║  THOTH Docker Build                         ║"
echo "║  GPU Target: ${GPU_TARGETS}                        ║"
echo "║  Image: ${IMAGE_NAME}:${TAG}                       ║"
echo "║  Build Jobs: ${BUILD_JOBS}                          ║"
echo "╚══════════════════════════════════════════════╝"

# Build using THOTH as context, Dockerfile from docker/thoth/
docker build \
  --file "$SCRIPT_DIR/Dockerfile" \
  --build-arg GPU_TARGETS="$GPU_TARGETS" \
  --build-arg BUILD_JOBS="$BUILD_JOBS" \
  --tag "${IMAGE_NAME}:${TAG}" \
  --tag "${IMAGE_NAME}:rocm7.2-gfx1031" \
  "$PROJECT_ROOT/THOTH" &
build_pid=$!

guard_log="$PROJECT_ROOT/THOTH/logs/hephaestion/$(date +%Y%m%dT%H%M%S)_docker_build_guard.log"
"$SCRIPT_DIR/hephaestion-guard.sh" \
  --command-pid "$build_pid" \
  --ignore-missing-container \
  --log-file "$guard_log" &
guard_pid=$!

set +e
wait "$build_pid"
build_status=$?
set -e
kill "$guard_pid" >/dev/null 2>&1 || true
wait "$guard_pid" >/dev/null 2>&1 || true

if (( build_status != 0 )); then
  echo "❌ Build failed. Guard log: $guard_log" >&2
  exit "$build_status"
fi

echo ""
echo "✅ Build complete!"
echo "   Image: ${IMAGE_NAME}:${TAG}"
echo "   Also tagged: ${IMAGE_NAME}:rocm7.2-gfx1031"
echo "   Guard log: ${guard_log}"
echo ""
echo "Run with: cd $SCRIPT_DIR && ./up.sh"
