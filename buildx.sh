#!/usr/bin/env sh

VERSION=$(date +%Y%m%d)
REPO=mikenye
IMAGE=adsbexchange

# build temp image to get versions
docker build -t ${REPO}/${IMAGE}:temp .
docker run --rm --entrypoint cat ${REPO}/${IMAGE}:temp /VERSIONS >/tmp/${REPO}_${IMAGE}.current
docker run --rm --entrypoint cat ${REPO}/${IMAGE}:latest /VERSIONS >/tmp/${REPO}_${IMAGE}.latest

# Chevk for version changes between this build and :latest
echo ""
echo "Version changes:"
echo ""
diff /tmp/${REPO}_${IMAGE}.latest /tmp/${REPO}_${IMAGE}.current
DIFFEXITCODE=$?
echo ""

# If versions have changed from latest image, then we rebuild latest
if [ "$DIFFEXITCODE" -ne "0" ]; then
  # Build the image using buildx
  docker buildx build -t "${REPO}/${IMAGE}:${VERSION}" --compress --push --platform linux/amd64,linux/arm/v7,linux/arm64 .
  docker buildx build -t ${REPO}/${IMAGE}:latest --compress --push --platform linux/amd64,linux/arm/v7,linux/arm64 .
else
  echo "No version changes, nothing further to do."
  echo ""
fi

# Clean up
rm /tmp/${REPO}_${IMAGE}.current /tmp/${REPO}_${IMAGE}.latest
