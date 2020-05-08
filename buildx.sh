#!/usr/bin/env sh
#shellcheck shell=sh

VERSION=$(date +%Y%m%d)
REPO=mikenye
IMAGE=adsbexchange
PLATFORMS="linux/amd64,linux/arm/v6,linux/arm/v7,linux/arm64"

docker context use x86_64
export DOCKER_CLI_EXPERIMENTAL="enabled"
docker buildx use homecluster

# build temp image to get versions
if [ ! -z $FORCEPUSH ]; then
  docker build -t "${REPO}/${IMAGE}:temp" .
  docker run --rm --entrypoint cat "${REPO}/${IMAGE}:temp" /VERSIONS > "/tmp/${REPO}_${IMAGE}.current"
  docker run --rm --entrypoint cat "${REPO}/${IMAGE}:latest" /VERSIONS > "/tmp/${REPO}_${IMAGE}.latest"

  # Check for version changes between this build and :latest
  echo ""
  echo "Version changes:"
  echo ""
  diff "/tmp/${REPO}_${IMAGE}.latest" "/tmp/${REPO}_${IMAGE}.current"
  DIFFEXITCODE=$?
  echo ""
else
  DIFFEXITCODE=1
fi

# If versions have changed from latest image, then we rebuild latest
if [ "$DIFFEXITCODE" -ne "0" ]; then
  # Build the image using buildx
  docker buildx build -t "${REPO}/${IMAGE}:${VERSION}" --compress --push --platform "${PLATFORMS}" .
  docker buildx build -t "${REPO}/${IMAGE}:latest" --compress --push --platform "${PLATFORMS}" .
else
  echo "No version changes, not building/pushing."
  echo "To override, set FORCEPUSH=1."
  echo ""
fi

# Clean up
rm "/tmp/${REPO}_${IMAGE}.current" "/tmp/${REPO}_${IMAGE}.latest"
