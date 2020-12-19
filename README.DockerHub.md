# mikenye/adsbexchange

[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/mikenye/docker-adsbexchange/Deploy%20to%20Docker%20Hub)](https://github.com/mikenye/docker-adsbexchange/actions?query=workflow%3A%22Deploy+to+Docker+Hub%22)
[![Docker Pulls](https://img.shields.io/docker/pulls/mikenye/adsbexchange.svg)](https://hub.docker.com/r/mikenye/adsbexchange)
[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/mikenye/adsbexchange/latest)](https://hub.docker.com/r/mikenye/adsbexchange)
[![Discord](https://img.shields.io/discord/734090820684349521)](https://discord.gg/sTf9uYF)

Docker container to feed ADS-B data into [adsbexchange](https://www.adsbexchange.com). Designed to work in tandem with [mikenye/readsb-protobuf](https://hub.docker.com/r/mikenye/readsb-protobuf) or another BEAST provider. Builds and runs on x86, x86_64, arm32v6, arm32v7 & arm64v8.

The container pulls ADS-B information from a BEAST provider and sends data to [adsbexchange](https://www.adsbexchange.com).

For more information on [adsbexchange](https://www.adsbexchange.com), see here: [ADSBExchange How-To-Feed](https://adsbexchange.com/how-to-feed/). This container uses a modified version of the "script method" outlined on that page.

## Documentation

Please [read this container's detailed and thorough documentation in the GitHub repository.](https://github.com/mikenye/docker-adsbexchange/blob/master/README.md)