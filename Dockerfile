FROM debian:stable-slim

ENV ADSBX_JSON_PATH="/run/adsbexchange-feed" \
    BEASTPORT=30005 \
    LOG_INTERVAL=900 \
    REDUCE_INTERVAL="0.5" \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    UUID_FILE="/boot/adsbx-uuid"

RUN set -x && \
    apt-get update -y && \
    apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    cmake \
    curl \
    debhelper \
    git \
    gnupg \
    jq \
    libusb-1.0-0 \
    libusb-1.0-0-dev \
    ncurses-dev \
    ntp \
    procps \
    python \
    python3-dev \
    uuid-runtime \
    && \
    git config --global advice.detachedHead false && \
    echo "========== Get ADSBX ==========" && \
    git clone https://github.com/adsbxchange/adsb-exchange.git /src/adsb-exchange && \
    export BRANCH_MLATCLIENT=$(grep -e "^MLAT_VERSION=" /src/adsb-exchange/setup.sh | cut -d "=" -f 2 | tr -d '"') && \
    export BRANCH_READSB=$(grep -e "^READSB_VERSION=" /src/adsb-exchange/setup.sh | cut -d "=" -f 2 | tr -d '"') && \
    echo "========== Install mlat-client ==========" && \
    git clone https://github.com/adsbxchange/mlat-client.git /src/mlat-client && \
    cd /src/mlat-client && \
    git checkout "${BRANCH_MLATCLIENT}" && \
    echo "mlat-client ${BRANCH_MLATCLIENT}" >> /VERSIONS && \
    dpkg-buildpackage -b -uc && \
    cd /src && \
    dpkg -i mlat-client_*.deb && \
    rm mlat-client_*.deb && \
    # echo "========== Install RTL-SDR ==========" && \
    # git clone git://git.osmocom.org/rtl-sdr.git /src/rtl-sdr && \
    # cd /src/rtl-sdr && \
    # export BRANCH_RTLSDR=$(git tag --sort="-creatordate" | head -1) && \
    # git checkout tags/"${BRANCH_RTLSDR}" && \
    # echo "rtl-sdr ${BRANCH_RTLSDR}" >> /VERSIONS && \
    # mkdir -p /src/rtl-sdr/build && \
    # cd /src/rtl-sdr/build && \
    # cmake ../ -DINSTALL_UDEV_RULES=ON -Wno-dev && \
    # make -Wstringop-truncation && \
    # make -Wstringop-truncation install && \
    # cp -v /src/rtl-sdr/rtl-sdr.rules /etc/udev/rules.d/ && \
    # echo "========== Blacklist RTL-SDR dongle ==========" && \
    # mkdir -p /etc/modprobe.d && \
    # echo "blacklist dvb_usb_rtl28xxu" >> /etc/modprobe.d/no-rtl.conf && \
    # echo "blacklist rtl2832" >> /etc/modprobe.d/no-rtl.conf && \
    # echo "blacklist rtl2830" >> /etc/modprobe.d/no-rtl.conf && \
    echo "========== Install readsb ==========" && \
    git clone https://github.com/adsbxchange/readsb.git /src/readsb && \
    cd /src/readsb && \
    git checkout "${BRANCH_READSB}" && \
    echo "readsb ${BRANCH_READSB}" >> /VERSIONS && \
    #make -j RTLSDR=yes && \
    make && \
    mv viewadsb /usr/local/bin/ && \
    mv readsb /usr/local/bin/ && \
    echo "========== Install adsbexchange-stats ==========" && \
    git clone https://github.com/adsbxchange/adsbexchange-stats.git /src/adsbexchange-stats && \
    cd /src/adsbexchange-stats && \
    echo "adsbexchange-stats $(git log | head -1)" >> /VERSIONS && \
    mv /src/adsbexchange-stats/json-status /usr/local/bin/json-status && \
    mkdir -p /run/adsbexchange-stats && \
    echo "========== Deploy s6-overlay ==========" && \
    curl -s https://raw.githubusercontent.com/mikenye/deploy-s6-overlay/master/deploy-s6-overlay.sh | sh && \
    echo "========== Clean up build environment ==========" && \
    apt-get remove -y \
    autoconf \
    automake \
    binutils \
    bsdmainutils \
    build-essential \
    bzip2 \
    cpp \
    cpp-8 \
    debhelper \
    g++ \
    g++-8 \
    gcc \
    gcc-8 \
    git \
    git \
    gnupg \
    libusb-1.0-0-dev \
    make \
    man-db \
    ncurses-dev \
    ntp \
    procps \
    python3-dev \
    sensible-utils \
    xz-utils \
    && \
    apt-get purge -y && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /src && \
    echo "========== Done! ==========" && \
    echo "========== Versions of all items built ==========" && \
    cat /VERSIONS

COPY etc/ /etc/
COPY scripts/ /scripts/

ENTRYPOINT [ "/init" ]
