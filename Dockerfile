FROM ghcr.io/sdr-enthusiasts/docker-baseimage:wreadsb

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
    ADSB_FEED_DESTINATION_HOSTNAME="feed1.adsbexchange.com" \
    ADSB_FEED_DESTINATION_PORT="30004" \
    ADSB_FEED_DESTINATION_TYPE="beast_reduce_out" \
    ADSB_FEED_SECONDARY_DESTINATION_HOSTNAME="feed2.adsbexchange.com" \
    ADSB_FEED_SECONDARY_DESTINATION_PORT="64004" \
    MLAT_FEED_DESTINATION_HOSTNAME="feed.adsbexchange.com" \
    MLAT_FEED_DESTINATION_PORT="31090"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY rootfs/ /

# hadolint ignore=DL3008,SC2086,SC2039,SC2068
RUN set -x && \
    apt-get update && \
    TEMP_PACKAGES=() && \
    TEMP_PACKAGES+=(git) && \
    KEPT_PACKAGES=() && \
    # Required for healthcheck
    KEPT_PACKAGES+=(jq) && \
    apt-get install -y --no-install-recommends \
    ${KEPT_PACKAGES[@]} \
    ${TEMP_PACKAGES[@]} \
    && \
    # adsbexchange-stats
    git clone --depth 1 'https://github.com/adsbxchange/adsbexchange-stats.git' /src/adsbexchange-stats && \
    pushd /src/adsbexchange-stats && \
    echo "adsbexchange-stats $(git log | head -1)" >> /VERSIONS && \
    mv /src/adsbexchange-stats/json-status /usr/local/bin/json-status && \
    popd && \
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
    #sed -i 's/ root / adsbx /g' /etc/s6/init/init-stage2-fixattrs.txt && \
    #redirfd -r 0 /etc/s6/init/init-stage2-fixattrs.txt fix-attrs && \
    # Simple date/time versioning
    date +%Y%m%d.%H%M > /CONTAINER_VERSION && \
    # Clean-up
    apt-get autoremove -q -o APT::Autoremove::RecommendsImportant=0 -o APT::Autoremove::SuggestsImportant=0 -y "${TEMP_PACKAGES[@]}" && \
    apt-get clean -q -y && \
    rm -rf /src/* /tmp/* /var/lib/apt/lists/* && \
    bash /scripts/clean-build.sh

# Add healthcheck
HEALTHCHECK --start-period=300s --interval=300s CMD /scripts/healthcheck.sh

# Rootless
USER 1000:1000
