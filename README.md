# mikenye/adsbexchange

Docker container to feed ADSB data into adsbexchange. Designed to work in tandem with mikenye/piaware or another BEAST provider. Builds and runs on x86_64, arm32v6, arm32v7 & arm64v8 (see below).

The container pulls ADS-B information from the [mikenye/readsb](https://hub.docker.com/repository/docker/mikenye/readsb) container (or another host providing data in BEAST format) and sends data to adsbexchange.

For more information on adsbexchange, see here: [ADSBExchange How-To-Feed](https://adsbexchange.com/how-to-feed/). This container uses a modified version of the "script method" outlines on that page.

## Supported tags and respective Dockerfiles

* `latest` is built nightly from the [`master` branch](https://github.com/mikenye/docker-adsbexchange/tree/master) [`Dockerfile`](https://github.com/mikenye/docker-adsbexchange/blob/master/Dockerfile) for all supported architectures. It contains:
  * Versions of `mlat-client` and `readsb` specified in [adsbxchange/adsb-exchange/setup.sh](https://github.com/adsbxchange/adsb-exchange/blob/master/setup.sh)
  * Latest version of `adsbexchange-stats`
  * Latest released version of `rtl-sdr`
* `development` ([`dev` branch](https://github.com/mikenye/docker-adsbexchange/tree/master), [`Dockerfile`](https://github.com/mikenye/docker-adsbexchange/blob/master/Dockerfile), `amd64` architecture only, built on commit, not recommended for production)
* Specific version and architecture tags are available if required, however these are not regularly updated. It is generally recommended to run `latest`.

## Multi Architecture Support

Currently, this image should pull and run on the following architectures:

* ```amd64```: Linux x86-64
* ```arm32v6```: ARMv6 32-bit (Pi Zero)
* ```arm32v7```, ```armv7l```: ARMv7 32-bit (Odroid HC1/HC2/XU4, RPi 2/3/4)
* ```arm64v8```, ```aarch64```: ARMv8 64-bit (RPi 4)

## Configuring `mikenye/readsb` Container

If you're using this container with the `mikenye/readsb` container to provide ModeS/BEAST data, you'll need to ensure you've opened port 30005 into the `mikenye/readsb` container, so this container can connect to it.

The IP address or hostname of the docker host running the `mikenye/readsb` container should be passed to the `mikenye/adsbexchange` container via the `BEASTHOST` environment variable shown below. The port can be changed from the default of 30005 with the optional `BEASTPORT` environment variable if required.

The latitude and longitude of your antenna must be passed via the `LAT` and `LONG` environment variables respectively.

The altitude of your antenna must be passed via the `ANT` environment variable respectively. Defaults to metres, but units may specified with a 'ft' or 'm' suffix.

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
 -e TZ="YOUR_TIMEZONE" \
 -e BEASTHOST=beasthost \
 -e TZ=Australia/Perth \
 -e LAT=-33.33333 \
 -e LONG=111.11111 \
 -e ALT=50m \
 -e SITENAME=My_Cool_ADSB_Receiver \
 -e UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
 mikenye/adsbexchange
```

## Up-and-Running with Docker Compose

```json
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

### 20200627

* Add `MLAT_INPUT_TYPE` - Expose `mlat-client`'s `--input-type`, for people using alternative ADS-B receivers.

### 20200612

* Set default of `PRIVATE_MLAT` to `false`

### 20200611

* Add `PRIVATE_MLAT` environment variable (thanks to @kyleinprogress!)

### 20200610

* Add docker healthcheck
* Add architectures `linux/386`

### 20200508

* Change `readsb` over to adsbexchange fork
* Change `readsb` & `mlat-client` versions to branches specified in <https://github.com/adsbxchange/adsb-exchange/blob/master/setup.sh>
* Change `readsb` `--write-json` path to `/run/adsbexchange-feed` to work with updated `adsbexchange-stats`
* Add `REDUCE_INTERVAL` environment variable to change frequency of data submitted to adsbexchange
* Make `UUID` required
* Add support for `arm32v6` architecture (for Pi Zero users)

### 20200505

* Configure `mlat-client` to listen on TCP port `30105` for use with tools such as [`graphs1090`](https://github.com/mikenye/docker-graphs1090)
* Bump `readsb` version to `v3.8.3`

### 20200320

* Linting and tidy up (thanks ShoGinn)
* Thanks to [ShoGinn](https://github.com/ShoGinn) for many contributions to the 20200320 release and tidy up of code & readme.

### 20200227

* Revert from `master` to `0.6.0` branch for `rtl-sdr` due to compilation problems
* Implement single `Dockerfile` for multi-architecture
* Change s6-overlay deployment method
* Implement buildx

### 20200212

* Change data submission method from `socat` to `readsb` (requested in [Issue #1](https://github.com/mikenye/docker-adsbexchange/issues/1#issue-563773894))
* Add [adsbxchange/adsbexchange-stats](https://github.com/adsbxchange/adsbexchange-stats) (suggested in [Issue #1](https://github.com/mikenye/docker-adsbexchange/issues/1#issuecomment-585067817))
* Add ability to pass a static site UUID via environment variable

### 20200204

* Original image
