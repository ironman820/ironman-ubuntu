#!/bin/bash

set -ouex pipefail

RELEASE="$(grep 'RELEASE' /etc/lsb-release | awk -F= '{print $2}')"

if [[ "$RELEASE" = "22.04" ]]; then
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg \
        --dearmor > packages.microsoft.gpg && \
    install -D -o root -g root -m 644 \
        packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg && \
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
        > /etc/apt/sources.list.d/vscode.list && \
    rm -f packages.microsoft.gpg && \
    DEBIAN_FRONTEND=noninteractive apt-get -y remove gpg && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install apt-transport-https duf \
        exa bat flatpak-xdg-utils pdftk-java ripgrep && \
    DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y code

    GLOCOM_VERSION="6.7.2"
    curl -fsL "https://downloads.bicomsystems.com/desktop/glocom/public/${GLOCOM_VERSION}/glocom/gloCOM-${GLOCOM_VERSION}.deb" \
        -o /tmp/glocom.deb && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install qtwayland5 \
        libpulse-mainloop-glib0 /tmp/glocom.deb && \
    rm -f /tmp/glocom.deb

    GO_VERSION="1.20.3"
    curl -fsL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" \
        -o /tmp/go.tar.gz && \
    tar -C /usr/local -xzf /tmp/go.tar.gz && \
    rm /tmp/go.tar.gz && \
    echo "export PATH=\$PATH:/usr/local/go/bin" >> /etc/profile

    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install nodejs

    DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install texlive-latex-recommended
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
