FROM debian:buster-20220125-slim

ENV ADSBX_JSON_PATH="/run/adsbexchange-feed" \
    ADSBX_STATS_PATH="/run/adsbexchange-stats" \
    BEASTPORT=30005 \
    LOG_INTERVAL=900 \
    REDUCE_INTERVAL="0.5" \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    # Below env var required to suppress errors on init for rootless operation
    S6_READ_ONLY_ROOT=1 \
    URL_HEALTHCHECKS_FRAMEWORK_REPO="https://github.com/mikenye/docker-healthchecks-framework.git" \
    URL_MLAT_CLIENT_REPO="https://github.com/adsbxchange/mlat-client.git" \
    URL_READSB_REPO="https://github.com/adsbxchange/readsb.git" \
    URL_ADSBX_SETUPSCRIPTS_REPO="https://github.com/adsbxchange/adsb-exchange.git" \
    URL_ADSBX_STATS="https://github.com/adsbxchange/adsbexchange-stats.git" \
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
    apt-get update -y && \
    TEMP_PACKAGES=() && \
    KEPT_PACKAGES=() && \
    # Required for healthcheck
    KEPT_PACKAGES+=(bc) && \
    KEPT_PACKAGES+=(jq) && \
    KEPT_PACKAGES+=(dnsutils) && \
    KEPT_PACKAGES+=(net-tools) && \
    KEPT_PACKAGES+=(procps) && \
    # Required for adsbexchange
    KEPT_PACKAGES+=(uuid-runtime) && \
    # Required for building multiple packages
    TEMP_PACKAGES+=(build-essential) && \
    TEMP_PACKAGES+=(cmake) && \
    # Required for building readsb
    TEMP_PACKAGES+=(zlib1g-dev) && \
    TEMP_PACKAGES+=(ncurses-dev) && \
    # Required for downloading stuff (ca-certificates & curl kept for health_from_adsbexchange.py)
    KEPT_PACKAGES+=(ca-certificates) && \
    KEPT_PACKAGES+=(curl) && \
    TEMP_PACKAGES+=(git) && \
    # Packages for s6-overlay deployment.
    TEMP_PACKAGES+=(file) && \
    TEMP_PACKAGES+=(gnupg) && \
    # Required to build mlat-client
    TEMP_PACKAGES+=(debhelper) && \
    TEMP_PACKAGES+=(python3-dev) && \
    KEPT_PACKAGES+=(python3) && \
    TEMP_PACKAGES+=(python3-pip) && \
    TEMP_PACKAGES+=(python3-wheel) && \
    TEMP_PACKAGES+=(python3-setuptools) && \
    TEMP_PACKAGES+=(python-distutils-extra) && \
    # Install packages
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ${KEPT_PACKAGES[@]} \
        ${TEMP_PACKAGES[@]} \
        && \
    git config --global advice.detachedHead false && \
    # Clone adsb-exchange & get versions of mlat-client & readsb to use
    git clone --depth 1 "${URL_ADSBX_SETUPSCRIPTS_REPO}" /src/adsb-exchange && \
    # BRANCH_MLATCLIENT=$(grep -e "^MLAT_VERSION=" /src/adsb-exchange/setup.sh | cut -d "=" -f 2 | tr -d '"') && \
    BRANCH_MLATCLIENT=$(git ls-remote "${URL_MLAT_CLIENT_REPO}" | grep HEAD | cut -f1) && \
    # BRANCH_READSB=$(grep -e "^READSB_VERSION=" /src/adsb-exchange/setup.sh | cut -d "=" -f 2 | tr -d '"') && \
    BRANCH_READSB=$(git ls-remote "${URL_READSB_REPO}" | grep HEAD | cut -f1) && \
    # Deploy mlat-client
    git clone --depth 1 "${URL_MLAT_CLIENT_REPO}" /src/mlat-client && \
    pushd /src/mlat-client && \
    git checkout "${BRANCH_MLATCLIENT}" && \
    echo "mlat-client ${BRANCH_MLATCLIENT}" >> /VERSIONS && \
    dpkg-buildpackage -b -uc && \
    pushd /src && \
    dpkg -i mlat-client_*.deb && \
    rm mlat-client_*.deb && \
    popd && popd && \
    # Deploy readsb
    git clone --depth 1 "${URL_READSB_REPO}" /src/readsb && \
    pushd /src/readsb && \
    git checkout "${BRANCH_READSB}" || true && \
    echo "readsb ${BRANCH_READSB}" >> /VERSIONS && \
    make AIRCRAFT_HASH_BITS=12 && \
    mv viewadsb /usr/local/bin/ && \
    mv readsb /usr/local/bin/ && \
    popd && \
    # Deploy rpi userland binaries (vcgencmd + others)
    git clone --depth 1 https://github.com/raspberrypi/userland.git /src/raspberrypi/userland && \
    pushd /src/raspberrypi/userland && \
    # Remove sudo - this script runs as root
    sed -i 's/sudo//g' ./buildme && \
    ./buildme "--$(uname -m)" && \
    echo '/opt/vc/lib' > /etc/ld.so.conf.d/rpi_userland.conf && \
    ldconfig && \
    popd && \
    # Deploy adsbexchange-stats
    python3 -m pip install --no-cache-dir vcgencmd && \
    git clone --depth 1 "${URL_ADSBX_STATS}" /src/adsbexchange-stats && \
    pushd /src/adsbexchange-stats && \
    echo "adsbexchange-stats $(git log | head -1)" >> /VERSIONS && \
    mv /src/adsbexchange-stats/json-status /usr/local/bin/json-status && \
    popd && \
    # Fix for issue #41 (https://github.com/mikenye/docker-adsbexchange/issues/41)
    sed -i 's/vcgencmd get_throttled/\/scripts\/vcgencmd_get_throttled_wrapper.sh/g' /usr/local/bin/json-status && \
    # Deploy s6-overlay
    curl -s https://raw.githubusercontent.com/mikenye/deploy-s6-overlay/master/deploy-s6-overlay.sh | sh && \
    # Deploy healthchecks framework
    git clone \
      --depth=1 \
      "$URL_HEALTHCHECKS_FRAMEWORK_REPO" \
      /opt/healthchecks-framework \
      && \
    rm -rf \
      /opt/healthchecks-framework/.git* \
      /opt/healthchecks-framework/*.md \
      /opt/healthchecks-framework/tests \
      && \
    # Clean-up
    apt-get remove -y ${TEMP_PACKAGES[@]} && \
    apt-get autoremove -y && \
    rm -rf /src/* /tmp/* /var/lib/apt/lists/* && \
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
    redirfd -r 0 /etc/s6/init/init-stage2-fixattrs.txt fix-attrs && \
    # Document versions
    cat /VERSIONS

ENTRYPOINT [ "/init" ]

# Add healthcheck
HEALTHCHECK --start-period=300s --interval=300s CMD /scripts/healthcheck.sh

# Rootless
USER 1000:1000
