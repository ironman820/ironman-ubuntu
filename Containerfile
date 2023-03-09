FROM quay.io/toolbx-images/ubuntu-toolbox:22.04

LABEL com.github.containers.toolbox="true" \
      name="ubuntu-toolbox" \
      version="22.04" \
      usage="This image is meant to be used with the toolbox command" \
      summary="Base image for creating Ubuntu toolbox containers" \
      maintainer="Ievgen Popovych <jmennius@gmail.com>"

# Remove apt configuration optimized for containers
# Remove docker-gzip-indexes to help with "command-not-found"
RUN rm /etc/apt/apt.conf.d/docker-gzip-indexes /etc/apt/apt.conf.d/docker-no-languages

# Enable myhostname nss plugin for clean hostname resolution without patching
# hosts (at least for sudo), add it right after 'files' entry. We expect that
# this entry is not present yet. Do this early so that package postinst (which
# adds it too late in the order) skips this step
RUN sed -Ei 's/^(hosts:.*)(\<files\>)\s*(.*)/\1\2 myhostname \3/' /etc/nsswitch.conf

# Restore documentation but do not upgrade all packages
# Install ubuntu-minimal & ubuntu-standard
# Install extra packages as well as libnss-myhostname
COPY extra-packages /
RUN sed -Ei '/apt-get (update|upgrade)/s/^/#/' /usr/local/sbin/unminimize && \
    apt-get update && \
    yes | /usr/local/sbin/unminimize && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install \
        ubuntu-minimal ubuntu-standard \
        libnss-myhostname \
        wget gpg \
        $(cat extra-packages | xargs) && \
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg && \
    install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg && \
    sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list' && \
    rm -f packages.microsoft.gpg && \
    DEBIAN_FRONTEND=noninteractive apt -y install apt-transport-https && \
    apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y code && \
    rm -rd /var/lib/apt/lists/*
RUN rm /extra-packages

# Fix empty bind-mount to clear selinuxfs (see #337)
RUN mkdir /usr/share/empty

# Add flatpak-spawn to /usr/bin
RUN ln -s /usr/libexec/flatpak-xdg-utils/flatpak-spawn /usr/bin/ && \
    ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/docker && \
      ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/flatpak && \ 
      ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/podman && \
      ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/rpm-ostree
