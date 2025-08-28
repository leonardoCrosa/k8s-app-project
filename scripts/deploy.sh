#!/usr/bin/env bash

# Makes script exit if a command fails or variable is undefined
set -euo pipefail

# variables helm uses for the release
APP_RELEASE="custom-nginx"
CHART_DIR="../deployments/helm/custom-nginx"
NS="custom-nginx"
IMAGE_REPO="lcrosa/custom-nginx"

# Docker image built with current git code version sha as tag. This way docker image tag matches code.
GIT_SHA=$(git rev-parse --short=12 HEAD)
IMAGE_TAG=git-${GIT_SHA}

# Builds the docker image with this tag
echo "==> Building Image ${IMAGE_REPO}:${IMAGE_TAG}"
docker build -t "${IMAGE_REPO}:${IMAGE_TAG}" ../app/

# Push Built Image
echo "==> Pushing Image"
docker push "${IMAGE_REPO}:${IMAGE_TAG}"

# Deploy Helm Release using Image Built
echo "==> Helm Upgrade/Install (${APP_RELEASE}) to namespace ${NS}"
helm upgrade --install "${APP_RELEASE}" "${CHART_DIR}" \
  -n "${NS}" --create-namespace \
  --set image.repository="${IMAGE_REPO}" \
  --set-string image.tag="${IMAGE_TAG}" \
  --wait --atomic --timeout 10m

# Check status while deployment is rolling out (Automatically get deployment name from the instance app label. Helm auto applies these labels to its releases)
# "get deploy" is outputed as a json of items that match my search. Meaning all deployments belonging to my helm app release.
# From the output it only picks item [0] and its name. In this case my release only has one deployment, and i only want its unique name, so this is great.
DEPLOY_NAME="$(kubectl -n "${NS}" get deploy \
  -l app.kubernetes.io/instance="${APP_RELEASE}" \
  -o jsonpath='{.items[0].metadata.name}')"
# Watches deployment status until it finishes or fails by timeout (rollout status deploy runs untill deploy finishes or times out. Great to exit script if errors)
echo "==> Waiting for rollout of ${DEPLOY_NAME}"
kubectl -n "${NS}" rollout status deploy/"${DEPLOY_NAME}" --timeout=5m

# Print the ALB DNS if there is an Ingress
echo "==> Ingress hostname (if any):"
kubectl -n "${NS}" get ingress -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}'
echo || true

# If script didnt exit before this, it means depoloy was successfull
echo "✅ Done. Deployed ${IMAGE_REPO}:${IMAGE_TAG}"
