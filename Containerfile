ARG UBUNTU_MAINVERSION=22.04

FROM quay.io/toolbx-images/ubuntu-toolbox:${UBUNTU_MAINVERSION}

LABEL com.github.containers.toolbox="true" \
      name="ubuntu-toolbox" \
      version="22.04" \
      usage="This image is meant to be used with the toolbox command" \
      summary="Base image for creating Ubuntu toolbox containers" \
      maintainer="Ievgen Popovych <jmennius@gmail.com>"

# Enable myhostname nss plugin for clean hostname resolution without patching
# hosts (at least for sudo), add it right after 'files' entry. We expect that
# this entry is not present yet. Do this early so that package postinst (which
# adds it too late in the order) skips this step
RUN sed -Ei 's/^(hosts:.*)(\<files\>)\s*(.*)/\1\2 myhostname \3/' /etc/nsswitch.conf

# Restore documentation but do not upgrade all packages
# Install ubuntu-minimal & ubuntu-standard
# Install extra packages as well as libnss-myhostname
COPY extra-packages /
ENV host_spawn_version="1.2.1" \ LANG=en_US.UTF-8 \ LANGUAGE=en_US:en \ LC_ALL=en_US.UTF-8
# RUN sed -Ei '/apt-get (update|upgrade)/s/^/#/' /usr/local/sbin/unminimize && \
#     apt update && \
#     yes | /usr/local/sbin/unminimize && \
RUN apt update && \
    apt upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt -y install \
        ubuntu-minimal ubuntu-standard \
        libnss-myhostname \
        wget gpg && \
    sed 's/# \(en_US.UTF-8 .*\)/\1/' -i /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    DEBIAN_FRONTEND=noninteractive apt -y install \
        $(cat extra-packages | xargs) && \
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg && \
    install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg && \
    sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list' && \
    rm -f packages.microsoft.gpg && \
    wget https://github.com/sigstore/cosign/releases/download/v2.0.0/cosign_2.0.0_amd64.deb -O /root/cosign.deb && \
    dpkg -i /root/cosign.deb && \
    rm -f /root/cosign.deb && \
    DEBIAN_FRONTEND=noninteractive apt -y remove gpg && \
    DEBIAN_FRONTEND=noninteractive apt -y install apt-transport-https && \
    apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y code && \
    curl -sS https://starship.rs/install.sh | sh -s -- -f && \
    curl -L "https://github.com/1player/host-spawn/releases/download/${host_spawn_version}/host-spawn-$(uname -m)" -o /usr/bin/host-spawn && \
    chmod +x /usr/bin/host-spawn
ENV fastfetch_version="1.11.0"
RUN curl -fsL "https://github.com/LinusDierheimer/fastfetch/releases/download/${fastfetch_version}/fastfetch-${fastfetch_version}-Linux.deb" -o /fastfetch.deb && \
    dpkg -i /fastfetch.deb && \
    rm -f /fastfetch.deb
RUN DEBIAN_FRONTEND=noninteractive apt-get clean && \
    rm -rd /var/lib/apt/lists/*
RUN rm /extra-packages

# Fix empty bind-mount to clear selinuxfs (see #337)
# RUN mkdir /usr/share/empty

# Add flatpak-spawn to /usr/bin
RUN ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/distrobox && \
    ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/docker && \
    ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/flatpak && \ 
    ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/podman && \
    ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/rpm-ostree && \
    ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/vim
