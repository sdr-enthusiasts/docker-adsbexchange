FROM debian:stable-slim

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    RTLSDRTAG=0.6.0 \
    MLATCLIENTTAG=v0.2.10 \
    BEASTPORT=30005 \
    LOG_INTERVAL=900 \
    UUID_FILE="/boot/adsbx-uuid"

RUN apt-get update -y && \
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
    mkdir /src && \
    cd /src && \
    git clone -b ${MLATCLIENTTAG} https://github.com/adsbxchange/mlat-client.git /src/mlat-client && \
    cd /src/mlat-client && \
    echo "mlat-client $(git log | head -1)" >> /VERSIONS && \
    dpkg-buildpackage -b -uc && \
    cd /src && \
    dpkg -i mlat-client_*.deb && \
    rm mlat-client_*.deb && \
    git clone -b ${RTLSDRTAG} git://git.osmocom.org/rtl-sdr.git /src/rtl-sdr && \
    mkdir -p /src/rtl-sdr/build && \
    cd /src/rtl-sdr/build && \
    echo "rtl-sdr $(git log | head -1)" >> /VERSIONS && \
    cmake ../ -DINSTALL_UDEV_RULES=ON -Wno-dev && \
    make -j -Wstringop-truncation && \
    make -j -Wstringop-truncation install && \
    git clone --depth 1 https://github.com/Mictronics/readsb.git /src/readsb && \
    cd /src/readsb && \
    echo "readsb $(git log | head -1)" >> /VERSIONS && \
    make -j RTLSDR=yes && \
    mv viewadsb /usr/local/bin/ && \
    mv readsb /usr/local/bin/ && \
    mkdir -p /run/readsb && \
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
    rm -rf /var/lib/apt/lists/* /src

COPY etc/ /etc/
COPY scripts/ /scripts/

ENTRYPOINT [ "/init" ]

