# docker build -t gstreamer-opencv:1.14.5-4.2.0 .
# adapted from https://gist.github.com/corenel/a615b6f7eb5b5425aa49343a7b409200
FROM nvidia/cuda:11.3.0-cudnn8-devel-ubuntu18.04

ENV HOME="/home/"
WORKDIR $HOME

### apt-get ###
RUN apt-get -y update && apt-get install -y \
    software-properties-common \
    build-essential \
    checkinstall \
    cmake \
    unzip \
    pkg-config \
    yasm \
    git \
    vim \
    curl \
    wget \
    gfortran \
    sudo \
    apt-transport-https \
    libcanberra-gtk-module \
    libcanberra-gtk3-module \
    dbus-x11 \
    vlc \
    iputils-ping \
    python3-dev \
    python3-pip

# cv2 dependencies
RUN apt-get -y update && apt-get install -y \
    libjpeg-dev \
    libpng-dev \
    libtiff-dev\
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev\
    libv4l-dev \
    libxvidcore-dev \
    libx264-dev\
    libgtk-3-dev\
    libatlas-base-dev

# gstreamer dependencies
RUN apt-get -y update && apt-get install -y \
    libgstreamer1.0-0 \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
    gstreamer1.0-doc \
    gstreamer1.0-tools \
    gstreamer1.0-x \
    gstreamer1.0-alsa \
    gstreamer1.0-gl \
    gstreamer1.0-gtk3 \
    gstreamer1.0-qt5 \
    gstreamer1.0-pulseaudio \
    gtk-doc-tools \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata python3-tk
ENV TZ=Asia/Singapore
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get clean && rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* && apt-get -y autoremove

### pip3 ###

RUN pip3 install --no-cache-dir --upgrade pip 

RUN pip3 install --no-cache-dir \
    setuptools==41.0.0 \
    protobuf==3.13.0 \
    numpy==1.15.4 \
    cryptography==2.3

RUN pip3 install --no-cache-dir --ignore-installed pyxdg==0.26

RUN pip3 install --no-cache-dir jupyter==1.0.0
RUN echo 'alias jup="jupyter notebook --allow-root --no-browser"' >> ~/.bashrc

### gstreamer ###
WORKDIR $HOME/gst-plugins-bad
COPY ./gst-plugins-bad $HOME/gst-plugins-bad
WORKDIR $HOME/gst-plugins-bad/
RUN NVENCODE_CFLAGS="-I/home/gst-plugins-bad/sys/nvenc" libgstnvdec_la_CFLAGS="-I/home/gst-plugins-bad/sys/nvenc" NVENCODE_LIBS="-L/home/gst-plugins-bad/sys/nvenc" libgstnvdec_la_LIBADD="-L/home/gst-plugins-bad/sys/nvenc" ./autogen.sh --with-cuda-prefix="/usr/local/cuda" 
WORKDIR $HOME/gst-plugins-bad/sys/nvenc
RUN make && cp .libs/libgstnvenc.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/
WORKDIR $HOME/gst-plugins-bad/sys/nvdec
RUN make && cp .libs/libgstnvdec.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/
