#!/bin/sh

VERSION=20200310
IMAGE=mikenye/adsbexchange

# Build the image using buildx
docker buildx build -t ${IMAGE}:${VERSION} --compress --push --platform linux/amd64,linux/arm/v7,linux/arm64 .
docker buildx build -t ${IMAGE}:latest --compress --push --platform linux/amd64,linux/arm/v7,linux/arm64 .

