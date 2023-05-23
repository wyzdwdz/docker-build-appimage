ARG TARGETARCH

FROM ubuntu:18.04 AS base

FROM base AS amd64
ARG ARCH=x86_64

FROM base AS arm64
ARG ARCH=aarch64

FROM ${TARGETARCH} AS selected
 
RUN apt update && apt -y upgrade
RUN apt -y install build-essential pkg-config git
RUN DEBIAN_FRONTEND=noninteractive apt -y install xorg

RUN apt -y install python3 python3-pip python3-markupsafe
RUN pip3 install conan==2.0.4
RUN conan profile detect

RUN apt -y install wget
WORKDIR /tmp
RUN wget https://github.com/Kitware/CMake/releases/download/v3.26.4/cmake-3.26.4-linux-${ARCH}.tar.gz
RUN tar -xf cmake-3.26.4-linux-${ARCH}.tar.gz
WORKDIR /tmp/cmake-3.26.4-linux-${ARCH}
RUN cp -rf * /usr
WORKDIR /tmp
RUN rm -rf cmake-3.26.4-linux-${ARCH}.tar.gz /tmp/cmake-3.26.4-linux-${ARCH}

WORKDIR /tmp
RUN wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-${ARCH}.AppImage
RUN cp appimagetool-${ARCH}.AppImage /usr/bin
RUN chmod a+x /usr/bin/appimagetool-${ARCH}.AppImage
RUN ln -sf /usr/bin/appimagetool-${ARCH}.AppImage /usr/bin/appimagetool
ENV APPIMAGE_EXTRACT_AND_RUN=1
RUN rm -rf appimagetool-${ARCH}.AppImage

WORKDIR /tmp
RUN git clone --recurse-submodules https://github.com/linuxdeploy/linuxdeploy.git
WORKDIR /tmp/linuxdeploy/build
RUN apt -y install patchelf libpng-dev libjpeg-dev
RUN cmake .. -DBUILD_TESTING=FALSE
RUN apt -y install software-properties-common
RUN add-apt-repository -y ppa:ubuntu-toolchain-r/test && apt update
RUN apt -y install gcc-9 g++-9
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 2 --slave /usr/bin/g++ g++ /usr/bin/g++-9
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 1 --slave /usr/bin/g++ g++ /usr/bin/g++-7
RUN update-alternatives --set gcc /usr/bin/gcc-9
RUN sed -i 's|#include "copyright.h"|#include "copyright/copyright.h"|g' /tmp/linuxdeploy/src/core/appdir.cpp
RUN make -j && make install
RUN update-alternatives --set gcc /usr/bin/gcc-7
WORKDIR /tmp
RUN rm -rf /tmp/linuxdeploy

ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN add-apt-repository -y ppa:deadsnakes/ppa && apt update
RUN apt -y install python3.7
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.7 1
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.6 2
RUN update-alternatives --set python3 /usr/bin/python3.7
RUN sed -i 's|#!/usr/bin/python3|#!/usr/bin/python3.6|g' /usr/bin/add-apt-repository