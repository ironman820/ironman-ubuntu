ARG UBUNTU_MAJOR_VERSION="${UBUNTU_MAJOR_VERSION:-22}"
ARG UBUNTU_MINOR_VERSION="${UBUNTU_MINOR_VERSION:-04}"
ARG UBUNTU_MAINVERSION="${UBUNTU_MAJOR_VERSION}.${UBUNTU_MINOR_VERSION}"

FROM quay.io/toolbx-images/ubuntu-toolbox:${UBUNTU_MAINVERSION}

LABEL com.github.containers.toolbox="true" \
      name="ubuntu-toolbox" \
      version="${UBUNTU_MAINVERSION}" \
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
ENV host_spawn_version="1.2.1" \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

RUN sed -Ei '/apt-get (update|upgrade)/s/^/#/' /usr/local/sbin/unminimize && \
    apt update && \
    yes | /usr/local/sbin/unminimize

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
        ubuntu-minimal ubuntu-standard \
        libnss-myhostname \
        wget gpg && \
    DEBIAN_FRONTEND=noninteractive apt-get clean

COPY extra-packages /tmp/
RUN sed 's/# \(en_US.UTF-8 .*\)/\1/' -i /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install \
        $(grep -v '^#' /tmp/extra-packages | xargs) && \
    DEBIAN_FRONTEND=noninteractive apt-get clean && \
    rm /tmp/extra-packages

RUN wget https://github.com/sigstore/cosign/releases/download/v2.0.0/cosign_2.0.0_amd64.deb -O /tmp/cosign.deb && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install /tmp/cosign.deb && \
    rm -f /tmp/cosign.deb && \
    DEBIAN_FRONTEND=noninteractive apt-get clean

RUN curl -sS https://starship.rs/install.sh | sh -s -- -f && \
    curl -L "https://github.com/1player/host-spawn/releases/download/${host_spawn_version}/host-spawn-$(uname -m)" -o /usr/bin/host-spawn && \
    chmod +x /usr/bin/host-spawn

ADD build.sh /tmp/build.sh
RUN /tmp/build.sh && \
    rm -f /tmp/build.sh

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y upgrade && \
    DEBIAN_FRONTEND=noninteractive apt-get clean && \
    rm -rd /var/lib/apt/lists/*

# Fix empty bind-mount to clear selinuxfs (see #337)
# RUN mkdir /usr/share/empty

# Add flatpak-spawn to /usr/bin
RUN ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/distrobox && \
    ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/docker && \
    ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/flatpak && \ 
    ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/podman && \
    ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/rpm-ostree
