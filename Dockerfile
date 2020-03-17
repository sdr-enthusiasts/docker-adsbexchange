FROM debian:stable-slim

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    BEASTPORT=30005 \
    LOG_INTERVAL=900 \
    UUID_FILE="/boot/adsbx-uuid"

RUN set -x && \
    apt-get update -y && \
    apt-get install -y --no-install-recommends \
        build-essential \
        debhelper \
        python \
        python3-dev \
        ntp \
        git \
        ca-certificates \
        procps \
        uuid-runtime \
        jq \
        curl \
        cmake \
        ncurses-dev \
        libusb-1.0-0 \
        libusb-1.0-0-dev \
        gnupg && \
    git config --global advice.detachedHead false && \
    echo "========== Install mlat-client ==========" && \
    git clone https://github.com/adsbxchange/mlat-client.git /src/mlat-client && \
    cd /src/mlat-client && \
    export BRANCH_MLATCLIENT=$(git tag --sort="-creatordate" | head -1) && \
    git checkout ${BRANCH_MLATCLIENT} && \
    echo "mlat-client ${BRANCH_MLATCLIENT}" >> /VERSIONS && \
    dpkg-buildpackage -b -uc && \
    cd /src && \
    dpkg -i mlat-client_*.deb && \
    rm mlat-client_*.deb && \
    echo "========== Install RTL-SDR ==========" && \
    git clone git://git.osmocom.org/rtl-sdr.git /src/rtl-sdr && \
    cd /src/rtl-sdr && \
    export BRANCH_RTLSDR=$(git tag --sort="-creatordate" | head -1) && \
    git checkout tags/${BRANCH_RTLSDR} && \
    echo "rtl-sdr ${BRANCH_RTLSDR}" >> /VERSIONS && \
    mkdir -p /src/rtl-sdr/build && \
    cd /src/rtl-sdr/build && \
    cmake ../ -DINSTALL_UDEV_RULES=ON -Wno-dev && \
    make -Wstringop-truncation && \
    make -Wstringop-truncation install && \
    cp -v /src/rtl-sdr/rtl-sdr.rules /etc/udev/rules.d/ && \
    echo "========== Blacklist RTL-SDR dongle ==========" && \
    mkdir -p /etc/modprobe.d && \
    echo "blacklist dvb_usb_rtl28xxu" >> /etc/modprobe.d/no-rtl.conf && \
    echo "blacklist rtl2832" >> /etc/modprobe.d/no-rtl.conf && \
    echo "blacklist rtl2830" >> /etc/modprobe.d/no-rtl.conf && \
    echo "========== Install readsb ==========" && \
    git clone https://github.com/Mictronics/readsb.git /src/readsb && \
    cd /src/readsb && \
    export BRANCH_READSB=$(git tag --sort="-creatordate" | head -1) && \
    git checkout tags/${BRANCH_READSB} && \
    echo "readsb ${BRANCH_RTLSDR}" >> /VERSIONS && \
    make -j RTLSDR=yes && \
    mv viewadsb /usr/local/bin/ && \
    mv readsb /usr/local/bin/ && \
    mkdir -p /run/readsb && \
    echo "========== Install adsbexchange-stats ==========" && \
    git clone https://github.com/adsbxchange/adsbexchange-stats.git /src/adsbexchange-stats && \
    cd /src/adsbexchange-stats && \
    echo "adsbexchange-stats $(git log | head -1)" >> /VERSIONS && \
    mv /src/adsbexchange-stats/json-status /usr/local/bin/json-status && \
    curl -s https://raw.githubusercontent.com/mikenye/deploy-s6-overlay/master/deploy-s6-overlay.sh | sh && \
    apt-get remove -y \
        build-essential \
        debhelper \
        python3-dev \
        ntp \
        git \
        procps \
        autoconf \
        automake \
        binutils \
        bsdmainutils \
        bzip2 \
        cpp \
        cpp-8 \
        g++ \
        g++-8 \
        gcc \
        gcc-8 \
        git \
        make \
        man-db \
        sensible-utils \
        ncurses-dev \
        libusb-1.0-0-dev \
        xz-utils \
        gnupg && \
    apt-get purge -y && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /src && \
    cat /VERSIONS

COPY etc/ /etc/
COPY scripts/ /scripts/

ENTRYPOINT [ "/init" ]
