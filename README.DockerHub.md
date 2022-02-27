# sdr-enthusiasts/docker-adsbexchange

[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/mikenye/adsbexchange/latest)](https://hub.docker.com/r/mikenye/adsbexchange)
[![Discord](https://img.shields.io/discord/734090820684349521)](https://discord.gg/sTf9uYF)

Docker container to feed ADS-B data into [adsbexchange](https://www.adsbexchange.com). Designed to work in tandem with [sdr-enthusiasts/readsb-protobuf](https://github.com/sdr-enthusiasts/docker-readsb-protobuf) or another BEAST provider. Builds and runs on x86, x86_64, arm32v6, arm32v7 & arm64v8.

The container pulls ADS-B information from a BEAST provider and sends data to [adsbexchange](https://www.adsbexchange.com).

For more information on [adsbexchange](https://www.adsbexchange.com), see here: [ADSBExchange How-To-Feed](https://adsbexchange.com/how-to-feed/). This container uses a modified version of the "script method" outlined on that page.

## Documentation

Please [read this container's detailed and thorough documentation in the GitHub repository.](https://github.com/sdr-enthusiasts/docker-adsbexchange/blob/main/README.md)