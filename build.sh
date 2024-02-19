#!/bin/bash

set -ouex pipefail

RELEASE="$(grep 'RELEASE' /etc/lsb-release | awk -F= '{print $2}')"

if [[ "$RELEASE" = "22.04" ]]; then
    GLOCOM_VERSION="6.7.2"
    curl -fsL "https://downloads.bicomsystems.com/desktop/glocom/public/${GLOCOM_VERSION}/glocom/gloCOM-${GLOCOM_VERSION}.deb" \
        -o /tmp/glocom.deb && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install qtwayland5 \
        libpulse-mainloop-glib0 /tmp/glocom.deb && \
    rm -f /tmp/glocom.deb
elif [[ "$RELEASE" = "18.04" ]]; then
    SCW_VERSION="2.2"
    curl -fsL "http://downloads.bicomsystems.com/desktop/apps/scw/${SCW_VERSION}/scwizard-${SCW_VERSION}-linux.deb" \
        -o /tmp/scwizard.deb && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install gtk2-engines \
        libcanberra-gtk-module /tmp/scwizard.deb && \
    rm -f /tmp/scwizard.deb
else
    echo "No packages to install."
fi

DEBIAN_FRONTEND=noninteractive apt-get clean
