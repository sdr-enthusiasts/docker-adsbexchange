FROM ghcr.io/fredclausen/docker-baseimage:base

ENV ADSBX_JSON_PATH="/run/adsbexchange-feed" \
    ADSBX_STATS_PATH="/run/adsbexchange-stats" \
    BEASTPORT=30005 \
    LOG_INTERVAL=900 \
    REDUCE_INTERVAL="0.5" \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    # Below env var required to suppress errors on init for rootless operation
    S6_READ_ONLY_ROOT=1 \
    PRIVATE_MLAT="false" \
    MLAT_INPUT_TYPE="dump1090" \
    ADSB_FEED_DESTINATION_HOSTNAME="feed.adsbexchange.com" \
    ADSB_FEED_DESTINATION_PORT="30004" \
    ADSB_FEED_DESTINATION_TYPE="beast_reduce_out" \
    ADSB_FEED_SECONDARY_DESTINATION_HOSTNAME="feed.adsbexchange.com" \
    ADSB_FEED_SECONDARY_DESTINATION_PORT="64004" \
    MLAT_FEED_DESTINATION_HOSTNAME="feed.adsbexchange.com" \
    MLAT_FEED_DESTINATION_PORT="31090"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY rootfs/ /

RUN set -x && \
    TEMP_PACKAGES=() && \
    KEPT_PACKAGES=() && \
    # Required for healthcheck
    KEPT_PACKAGES+=(jq) && \
    KEPT_PACKAGES+=(dnsutils) && \
    # # Required for adsbexchange
    KEPT_PACKAGES+=(uuid-runtime) && \
    # Required for building multiple packages
    TEMP_PACKAGES+=(git) && \
    TEMP_PACKAGES+=(build-essential) && \
    TEMP_PACKAGES+=(cmake) && \
    # Required for building readsb
    TEMP_PACKAGES+=(ncurses-dev) && \
    # mlat-client dependencies
    KEPT_PACKAGES+=(python3-minimal) && \
    KEPT_PACKAGES+=(python3-wheel) && \
    KEPT_PACKAGES+=(python3-pip) && \
    KEPT_PACKAGES+=(python3-setuptools) && \
    TEMP_PACKAGES+=(python3-dev) && \
    # raspberrypi/userland dependencies
    TEMP_PACKAGES+=(gcc) && \
    TEMP_PACKAGES+=(gcc-arm-linux-gnueabihf) && \
    TEMP_PACKAGES+=(g++) && \
    TEMP_PACKAGES+=(g++-arm-linux-gnueabihf) && \
    # Install packages
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ${KEPT_PACKAGES[@]} \
        ${TEMP_PACKAGES[@]} \
        && \
    # Clone adsb-exchange to get repo & branch of mlat-client & readsb
    git clone --depth 1 "https://github.com/adsbxchange/adsb-exchange.git" "/src/adsb-exchange" && \
    MLAT_REPO=$(grep -h '^MLAT_REPO=.*' /src/adsb-exchange/*.sh 2> /dev/null | head -1 | cut -d "=" -f 2 | tr -d '"') && \
    MLAT_BRANCH=$(grep -h '^MLAT_BRANCH=.*' /src/adsb-exchange/*.sh 2> /dev/null | head -1 | cut -d "=" -f 2 | tr -d '"') && \
    READSB_REPO=$(grep -h '^READSB_REPO=.*' /src/adsb-exchange/*.sh 2> /dev/null | head -1 | cut -d "=" -f 2 | tr -d '"') && \
    READSB_BRANCH=$(grep -h '^READSB_BRANCH=.*' /src/adsb-exchange/*.sh 2> /dev/null | head -1 | cut -d "=" -f 2 | tr -d '"') && \
    # readsb
    git clone --branch "$READSB_BRANCH" --depth 1 "$READSB_REPO" "/src/readsb" && \
    pushd "/src/readsb" && \
    make -j "$(nproc)" && \
    find "/src/readsb" -maxdepth 1 -executable -type f -exec cp -v {} /usr/local/bin/ \; && \
    popd && \
    ldconfig && \
    # mlat-client
    git clone --branch "$MLAT_BRANCH" --depth 1 "$MLAT_REPO" "/src/mlat-client" && \
    pushd /src/mlat-client && \
    ./setup.py build && \
    ./setup.py install && \
    popd && \
    ldconfig && \
    # raspberrypi/userland: clone repo
    git clone --depth 1 'https://github.com/raspberrypi/userland.git' /src/raspberrypi/userland && \
    # raspberrypi/userland: remove sudo - this script runs as root
    pushd /src/raspberrypi/userland && \
    sed -i 's/sudo//g' ./buildme && \
    # raspberrypi/userland: build & install
    ./buildme "--$(uname -m)" && \
    echo '/opt/vc/lib' > /etc/ld.so.conf.d/rpi_userland.conf && \
    ldconfig && \
    popd && \
    # vcgencmd
    python3 -m pip install --no-cache-dir vcgencmd && \
    # adsbexchange-stats
    git clone --depth 1 'https://github.com/adsbxchange/adsbexchange-stats.git' /src/adsbexchange-stats && \
    pushd /src/adsbexchange-stats && \
    echo "adsbexchange-stats $(git log | head -1)" >> /VERSIONS && \
    mv /src/adsbexchange-stats/json-status /usr/local/bin/json-status && \
    popd && \
    # Fix for issue #41 (https://github.com/mikenye/docker-adsbexchange/issues/41)
    sed -i 's/vcgencmd get_throttled/\/scripts\/vcgencmd_get_throttled_wrapper.sh/g' /usr/local/bin/json-status && \
    # Clean-up
    apt-get remove -y ${TEMP_PACKAGES[@]} && \
    apt-get autoremove -y && \
    rm -rf /src/* /tmp/* /var/lib/apt/lists/* && \
    # readsb: simple tests
    readsb --version && \
    viewadsb --version && \
    # Create user/group for rootless operation
    groupadd --gid 1000 adsbx --system && \
    useradd --uid 1000 --no-create-home --no-user-group --gid 1000 --system adsbx && \
    touch /boot/adsbx-uuid && \
    chown adsbx:adsbx /boot/adsbx-uuid && \
    # Set up symlinks for /etc/localtime & permissions for /etc/timezone for rootless operation
    chown adsbx:adsbx /etc/timezone && \
    chown adsbx:adsbx /run && \
    rm /etc/localtime && \
    ln -s /tmp/localtime /etc/localtime && \
    # Fix /etc/s6/init/init-stage2-fixattrs.txt for rootless operation
    sed -i 's/ root / adsbx /g' /etc/s6/init/init-stage2-fixattrs.txt && \
    redirfd -r 0 /etc/s6/init/init-stage2-fixattrs.txt fix-attrs

# Add healthcheck
HEALTHCHECK --start-period=300s --interval=300s CMD /scripts/healthcheck.sh

# Rootless
USER 1000:1000
