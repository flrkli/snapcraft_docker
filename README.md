# snapcraft_docker
Docker project for building a snapcraft image for armhf.

Note that this image is based on the official snapcraft docker image https://github.com/snapcore/snapcraft/tree/master/docker and the snapcraft armhf version for snapcraft 2.x from dawidcrivelli https://github.com/dawidcrivelli/snapcraft_armhf.

## Install

    docker pull flrkli/snapcraft:3.8-armhf
    sudo usermod -a -G docker $USER
    docker run --rm --privileged multiarch/qemu-user-static:register --reset

## Run

    docker run -v "$PWD":/build -w /build flrkli/snapcraft:3.8-armhf snapcraft

Compare https://snapcraft.io/docs/build-on-docker
