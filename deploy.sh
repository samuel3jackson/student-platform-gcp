#!/bin/bash
set -e

PROJECT_ID="infra-case-study"
REGION="us-central1"
REPO="student-platform"
IMAGE="api"
TAG="v10"

FULL_IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/${IMAGE}:${TAG}"

echo "=== Authenticating Docker with Artifact Registry ==="
cat service_account.json | docker login -u _json_key --password-stdin https://${REGION}-docker.pkg.dev

echo "=== Building Docker image for linux/amd64 ==="
docker build --platform linux/amd64 --no-cache -t ${FULL_IMAGE} ./backend

echo "=== Pushing to Artifact Registry ==="
docker push ${FULL_IMAGE}

echo "=== Done ==="
echo "Image pushed to: ${FULL_IMAGE}"