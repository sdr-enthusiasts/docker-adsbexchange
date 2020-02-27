# docker-adsbexchange
Docker container to feed ADSB data into adsbexchange. Designed to work in tandem with mikenye/piaware or another BEAST provider. Builds and runs on x86_64, arm32v7 & arm64v8 (see below).

The container pulls ModeS/BEAST information from the mikenye/piaware container (or another host providing ModeS/BEAST data), and sends data to adsbexchange.

For more information on adsbexchange, see here: https://adsbexchange.com/how-to-feed/. This container uses a modified version of the "script method" outlines on that page.

## Supported tags and respective Dockerfiles
* `latest`, `20200227` (`20200227` branch, `Dockerfile`)
* `20200212`
  * `20200212-amd64` (`20200212` branch, `Dockerfile.amd64`)
  * `20200212-arm32v7` (`20200212` branch, `Dockerfile.arm32v7`)
  * `20200212-arm64v8` (`20200212` branch, `Dockerfile.arm64v8`)
* `20200204`
  * `20200204-amd64` (`20200204` branch, `Dockerfile.amd64`)
  * `20200204-arm32v7` (`20200204` branch, `Dockerfile.arm32v7`)
  * `20200204-arm64v8` (`20200204` branch, `Dockerfile.arm64v8`)
* `development` (`master` branch, `Dockerfile.amd64`, `amd64` architecture only, not recommended for production)

## Changelog

### 20200227
 * Revert from `master` to `0.6.0` branch for `rtl-sdr` due to compliation problems
 * Implement single `Dockerfile` for multi-architecture
 * Change s6-overlay deployment method
 * Implement buildx

### 20200212
 * Change data submission method from `socat` to `readsb` (requested in [Issue #1](https://github.com/mikenye/docker-adsbexchange/issues/1#issue-563773894))
 * Add [adsbxchange/adsbexchange-stats](https://github.com/adsbxchange/adsbexchange-stats) (suggested in [Issue #1](https://github.com/mikenye/docker-adsbexchange/issues/1#issuecomment-585067817))
 * Add ability to pass a static site UUID via environment variable

### 20200204
 * Original image

## Multi Architecture Support
Currently, this image should pull and run on the following architectures:
 * ```amd64```: Linux x86-64
 * ```arm32v7```, ```armv7l```: ARMv7 32-bit (Odroid HC1/HC2/XU4, RPi 2/3/4)
 * ```arm64v8```, ```aarch64```: ARMv8 64-bit (RPi 4)

## Configuring `mikenye/piaware` Container
If you're using this container with the `mikenye/piaware` container to provide ModeS/BEAST data, you'll need to ensure you've opened port 30005 into the `mikenye/piaware` container, so this container can connect to it.

The IP address or hostname of the docker host running the `mikenye/piaware` container should be passed to the `mikenye/adsbexchange` container via the `BEASTHOST` environment variable shown below. The port can be changed from the default of 30005 with the optional `BEASTPORT` environment variable.

The latitude and longitude of your antenna must be passed via the `LAT` and `LONG` environment variables respectively.

The altitude of your antenna must be passed via the `ANT` environment variable respectively. Defaults to metres, but units may specified with a 'ft' or 'm' suffix.

Lastly, you should specify a site name via the `SITENAME` environment variable. This field supports letters, numbers, `-` & `_` only. Any other characters will be stripped upon container initialisation.

## Generating a site UUID ##

First-time users are encouraged to generate a static UUID.

In order to generate a site UUID, initially run the container with the following command:

```
docker run --rm -it --entrypoint uuidgen mikenye/adsbexchange -t
```

Take note of the UUID returned. You should pass it as the `UUID` environment variable when running the container.

You will be able to view your site's stats by visiting `https://www.adsbexchange.com/api/feeders/?feed=YOUR-UUID-HERE`. The link with your UUID will be printed to the container log when the container starts.

If you don't generate a static UUID, a dynamic UUID will be created when the container starts.

## Up-and-Running with `docker run`

```
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
 -e SITENAME=My_Cool_ADSB_Receiver
 -e UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
 mikenye/adsbexchange
```

## Up-and-Running with Docker Compose

```
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

## Up-and-Running with Docker Compose, including `mikenye/piaware`

```
version: '2.0'

services:

  piaware:
    image: mikenye/piaware:latest
    tty: true
    container_name: piaware
    mac_address: de:ad:be:ef:13:37
    restart: always
    devices:
      - /dev/bus/usb/001/004:/dev/bus/usb/001/004
    ports:
      - 8080:8080
      - 30005:30005
    environment:
      - TZ="Australia/Perth"
      - LAT=-33.33333
      - LONG=111.111111
    volumes:
      - /var/cache/piaware:/var/cache/piaware

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

For an explanation of the `mikenye/piaware` image's configuration, see that image's readme.


## Runtime Environment Variables

There are a series of available environment variables:

| Environment Variable | Purpose                         | Default |
| -------------------- | ------------------------------- | ------- |
| `BEASTHOST`          | Required. IP/Hostname of a Mode-S/BEAST provider (dump1090) | |
| `BEASTPORT`          | Optional. TCP port number of Mode-S/BEAST provider (dump1090) | 30005 |
| `TZ`                 | Your local timezone (optional)  | GMT     |
| `LAT`                | The latitude of the antenna (required) | |
| `LONG`               | The longitude of the antenna (required) | |
| `ALT`                | The altitude of the antenna ('m' or 'ft' suffix) | |
| `SITENAME`           | The name of your site (A-Z, a-z, `-`, `_`) | |
| `UUID`               | Your static UUID (optional, but recommended) | dynamically generated |


## Ports
This container required no incoming ports to be mapped.

## Logging
* All processes are logged to the container's stdout, and can be viewed with `docker logs [-f] container`.

