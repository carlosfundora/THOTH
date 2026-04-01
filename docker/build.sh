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

echo "╔══════════════════════════════════════════════╗"
echo "║  THOTH Docker Build                         ║"
echo "║  GPU Target: ${GPU_TARGETS}                        ║"
echo "║  Image: ${IMAGE_NAME}:${TAG}                       ║"
echo "╚══════════════════════════════════════════════╝"

# Build using THOTH as context, Dockerfile from docker/thoth/
docker build \
  --file "$SCRIPT_DIR/Dockerfile" \
  --build-arg GPU_TARGETS="$GPU_TARGETS" \
  --tag "${IMAGE_NAME}:${TAG}" \
  --tag "${IMAGE_NAME}:rocm7.2-gfx1031" \
  "$PROJECT_ROOT/THOTH"

echo ""
echo "✅ Build complete!"
echo "   Image: ${IMAGE_NAME}:${TAG}"
echo "   Also tagged: ${IMAGE_NAME}:rocm7.2-gfx1031"
echo ""
echo "Run with: cd $SCRIPT_DIR && docker compose up -d"
