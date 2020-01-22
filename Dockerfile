FROM multiarch/ubuntu-core:armhf-xenial as builder

# Prepare the cross build binaries
COPY bin/* /usr/bin/
# NPM settings for permissions under snap and cross-compilation
COPY npmrc /root/.npmrc
WORKDIR /build

RUN ["cross-build-start"]
# Grab dependencies
RUN apt-get update
RUN apt-get dist-upgrade --yes
RUN apt-get install --yes \
      curl \
      jq \
      squashfs-tools

# Grab the core snap from the stable channel and unpack it in the proper place
RUN curl -L $(curl -H 'X-Ubuntu-Series: 16' -H 'X-Ubuntu-Architecture: armhf' 'https://api.snapcraft.io/api/v1/snaps/details/core' | jq '.download_url' -r) --output core.snap
RUN mkdir -p /snap/core
RUN unsquashfs -d /snap/core/current core.snap

# Grab the snapcraft snap from the candidate channel and unpack it in the proper place
RUN curl -L $(curl -H 'X-Ubuntu-Series: 16' -H 'X-Ubuntu-Architecture: armhf' 'https://api.snapcraft.io/api/v1/snaps/details/snapcraft?channel=stable' | jq '.download_url' -r) --output snapcraft.snap
RUN mkdir -p /snap/snapcraft
RUN unsquashfs -d /snap/snapcraft/current snapcraft.snap

# Create a snapcraft runner
RUN mkdir -p /snap/bin
RUN echo "#!/bin/sh" > /snap/bin/snapcraft
RUN snap_version="$(awk '/^version:/{print $2}' /snap/snapcraft/current/meta/snap.yaml)" && echo "export SNAP_VERSION=\"$snap_version\"" >> /snap/bin/snapcraft
RUN echo 'exec "/usr/bin/python3" "$SNAP/bin/snapcraft" "$@"' >> /snap/bin/snapcraft
RUN chmod +x /snap/bin/snapcraft

RUN ["cross-build-end"]

# Multi-stage build, only need the snaps from the builder. Copy them one at a
# time so they can be cached.
FROM multiarch/ubuntu-core:armhf-xenial

# Prepare the cross build binaries
COPY bin/* /usr/bin/
# NPM settings for permissions under snap and cross-compilation
COPY npmrc /root/.npmrc
WORKDIR /build

COPY --from=builder /snap/core /snap/core
COPY --from=builder /snap/snapcraft /snap/snapcraft
COPY --from=builder /snap/bin/snapcraft /snap/bin/snapcraft

RUN ["cross-build-start"]
# Install python
RUN apt-get update \
  && apt-get install -y python3-pip python3-dev \
  && cd /usr/local/bin \
  && ln -s /usr/bin/python3 python \
  && pip3 install --upgrade pip

# Generate locale
RUN apt-get update && apt-get dist-upgrade --yes && apt-get install --yes sudo locales && locale-gen en_US.UTF-8

# Set the proper environment
ENV LANG="en_US.UTF-8"
ENV LANGUAGE="en_US:en"
ENV LC_ALL="en_US.UTF-8"
ENV PATH="/snap/bin:$PATH"
ENV SNAP="/snap/snapcraft/current"
ENV SNAP_NAME="snapcraft"
ENV SNAP_ARCH="armhf"

RUN ["cross-build-end"]
