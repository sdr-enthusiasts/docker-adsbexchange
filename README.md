# mikenye/adsbexchange

[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/mikenye/docker-adsbexchange/Deploy%20to%20Docker%20Hub)](https://github.com/mikenye/docker-adsbexchange/actions?query=workflow%3A%22Deploy+to+Docker+Hub%22)
[![Docker Pulls](https://img.shields.io/docker/pulls/mikenye/adsbexchange.svg)](https://hub.docker.com/r/mikenye/adsbexchange)
[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/mikenye/adsbexchange/latest)](https://hub.docker.com/r/mikenye/adsbexchange)
[![Discord](https://img.shields.io/discord/734090820684349521)](https://discord.gg/sTf9uYF)

Docker container to feed ADS-B data into [adsbexchange](https://www.adsbexchange.com). Designed to work in tandem with [mikenye/readsb-protobuf](https://hub.docker.com/r/mikenye/readsb-protobuf) or another BEAST provider. Builds and runs on x86, x86_64, arm32v6, arm32v7 & arm64v8.

The container pulls ADS-B information from a BEAST provider and sends data to [adsbexchange](https://www.adsbexchange.com).

For more information on [adsbexchange](https://www.adsbexchange.com), see here: [ADSBExchange How-To-Feed](https://adsbexchange.com/how-to-feed/). This container uses a modified version of the "script method" outlined on that page.

## Supported tags and respective Dockerfiles

* `latest` is built nightly from the [`master` branch](https://github.com/mikenye/docker-adsbexchange/tree/master) [`Dockerfile`](https://github.com/mikenye/docker-adsbexchange/blob/master/Dockerfile) for all supported architectures. It contains:
  * Versions of `mlat-client` and `readsb` specified in [adsbxchange/adsb-exchange/setup.sh](https://github.com/adsbxchange/adsb-exchange/blob/master/setup.sh)
  * Latest version of `adsbexchange-stats`
  * Latest released version of `rtl-sdr`
* `latest_nohealthcheck` is the same as the `latest` version above. However, this version has the docker healthcheck removed. This is done for people running platforms (such as [Nomad](https://www.nomadproject.io)) that don't support manually disabling healthchecks, where healthchecks are not wanted.
* Specific version and architecture tags are available if required, however these are not regularly updated. It is generally recommended to run `latest`.

## Configuring `mikenye/adsbexchange` Container

If you're using this container with the `mikenye/readsb` container to provide ModeS/BEAST data, you'll need to ensure you've opened port 30005 into the `mikenye/readsb` container, so this container can connect to it.

The IP address or hostname of the docker host running the `mikenye/readsb` container should be passed to the `mikenye/adsbexchange` container via the `BEASTHOST` environment variable shown below. The port can be changed from the default of 30005 with the optional `BEASTPORT` environment variable if required.

The latitude and longitude of your antenna must be passed via the `LAT` and `LONG` environment variables respectively.

The altitude of your antenna must be passed via the `ALT` environment variable respectively. Defaults to metres, but units may specified with a 'ft' or 'm' suffix.

A UUID for this feeder must be passed via the `UUID` environment variable (see below).

Lastly, you should specify a site name via the `SITENAME` environment variable. This field supports letters, numbers, `-` & `_` only. Any other characters will be stripped upon container initialization.

## Generating a site UUID Number

First-time users should generate a static UUID.

To do this, run a temporary container with the following command:

```shell
docker run --rm -it --entrypoint uuidgen mikenye/adsbexchange -t
```

Take note of the UUID returned. You should pass it as the `UUID` environment variable when running the container.

You will be able to view your site's stats by visiting `https://www.adsbexchange.com/api/feeders/?feed=YOUR-UUID-HERE`. The link with your UUID will be printed to the container log when the container starts.

## Up-and-Running with `docker run`

```shell
docker run \
 -d \
 --rm \
 --name adsbx \
 -e TZ=YOUR_TIMEZONE \
 -e BEASTHOST=beasthost \
 -e LAT=-33.33333 \
 -e LONG=111.11111 \
 -e ALT=50m \
 -e SITENAME=My_Cool_ADSB_Receiver \
 -e UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
 --tmpfs=/run:rw,nosuid,nodev,exec,relatime,size=64M,uid=1000,gid=1000 \
 mikenye/adsbexchange
```

## Up-and-Running with Docker Compose

```yaml
version: '2.0'

services:
  adsbexchange:
    image: mikenye/adsbexchange
    tty: true
    container_name: adsbx
    restart: always
    environment:
      - BEASTHOST=beasthost
      - TZ=Australia/Perth
      - LAT=-33.33333
      - LONG=111.11111
      - ALT=50m
      - SITENAME=My_Cool_ADSB_Receiver
      - UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    tmpfs:
      - /run:rw,nosuid,nodev,exec,relatime,size=64M,uid=1000,gid=1000
```

## Up-and-Running with Docker Compose, including `mikenye/readsb`

See [Guide to ADS-B Data Reception, Decoding & Sharing with RTLSDR & Docker](https://github.com/mikenye/docker-readsb/wiki/Guide-to-ADS-B-Data-Receiving,-Decoding-and-Sharing,-Leveraging-RTLSDR-and-Docker)

## Runtime Environment Variables

There are a series of available environment variables:

| Environment Variable | Purpose                                                                  | Default |
| -------------------- | ------------------------------------------------------------------------ | ------- |
| `BEASTHOST`          | Required. IP/Hostname of a Mode-S/BEAST provider (dump1090)              |         |
| `BEASTPORT`          | Optional. TCP port number of Mode-S/BEAST provider (dump1090)            | `30005`   |
| `UUID`               | Required. Your static UUID                                               |         |
| `LAT`                | Required. The latitude of the antenna                                    |         |
| `LONG`               | Required. The longitude of the antenna                                   |         |
| `ALT`                | Required. The altitude of the antenna above sea level. If positive (above sea level), must include either 'm' or 'ft' suffix to indicate metres or feet. If negative (below sea level), must have no suffix, and the value is interpreted in metres.  |         |
| `SITENAME`           | Required. The name of your site (A-Z, a-z, `-`, `_`)                     |         |
| `TZ`                 | Optional. Your local timezone                                            | `GMT`     |
| `REDUCE_INTERVAL`    | Optional. How often beastreduce data is transmitted to ADSBExchange. For low bandwidth feeds, this can be increased to `5` or even `10` | `0.5`     |
| `PRIVATE_MLAT`       | Optional. Setting this to true will prevent feeder being shown on the [ADS-B Exchange Feeder Map](https://map.adsbexchange.com/mlat-map/)| `false`     |
| `MLAT_INPUT_TYPE`    | Optional. Sets the input receiver type. Run `docker run --rm -it --entrypoint mlat-client mikenye/adsbexchange --help` and see `--input-type` for valid values. | `dump1090` |
| `ADSB_FEED_DESTINATION_HOSTNAME` | Optional. Allows changing the hostname that ADS-B data is fed to. | `feed.adsbexchange.com` |
| `ADSB_FEED_DESTINATION_PORT`     | Optional. Allows changing the TCP port that ADS-B data is fed to. | `30005` |
| `ADSB_FEED_DESTINATION_TYPE`     | Optional. Allows changing the `readsb` output data type. | `beast_reduce_out` |
| `MLAT_FEED_DESTINATION_HOSTNAME` | Optional. Allows changing the MLAT server hostname. | `feed.adsbexchange.com` |
| `MLAT_FEED_DESTINATION_PORT`     | Optional. Allows changing the MLAT server TCP port. | `31090` |

## Ports

| Port  | Purpose |
| ----- | ------- |
| `30105` | MLAT data in Beast format for tools such as [`graphs1090`](https://github.com/mikenye/docker-graphs1090) and/or [`tar1090`](https://github.com/mikenye/docker-tar1090)

## Logging

* All processes are logged to the container's stdout, and can be viewed with `docker logs [-f] container`.

## Getting help

Please feel free to [open an issue on the project's GitHub](https://github.com/mikenye/docker-adsbexchange/issues).

I also have a [Discord channel](https://discord.gg/sTf9uYF), feel free to [join](https://discord.gg/sTf9uYF) and converse.

## Changelog

See the [commit history](https://github.com/mikenye/docker-adsbexchange/commits/master) on GitHub.
