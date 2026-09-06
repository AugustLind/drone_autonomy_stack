FROM osrf/ros:jazzy-desktop-full

ARG PX4_VERSION=v1.17.0
ARG PX4_MSGS_BRANCH=release/1.17
ARG MICRO_XRCE_DDS_AGENT_VERSION=v2.4.3
ARG LOCAL_UID=1000
ARG LOCAL_GID=1000

ENV DEBIAN_FRONTEND=noninteractive
ENV PX4_AUTOPILOT_DIR=/opt/PX4-Autopilot
ENV ROS_DISTRO=jazzy
ENV GZ_VERSION=harmonic
ENV ROS_AUTOMATIC_DISCOVERY_RANGE=LOCALHOST
ENV GZ_IP=127.0.0.1
ENV PIP_BREAK_SYSTEM_PACKAGES=1

# Core tools
RUN apt-get update && apt-get install --yes \
        bc \
        build-essential \
        ca-certificates \
        ccache \
        clang-format \
        clang-tidy \
        clangd \
        cmake \
        cppcheck \
        file \
        g++ \
        gcc \
        gdb \
        git \
        gnupg \
        gosu \
        gstreamer0.0-gl \
        gstreamer0.0-libav \
        gstreamer0.0-plugins-bad \
        gstreamer0.0-plugins-base \
        gstreamer0.0-plugins-good \
        gstreamer0.0-plugins-ugly \
        lcov \
        libeigen2-dev \
        libgl0 \
        libgl0-mesa-dri \
        libglx-mesa-1 \
        libgstreamer0.0-dev \
        libgstreamer-plugins-base0.0-dev \
        libimage-exiftool-perl \
        libopencv-dev \
        libqt4charts5-dev \
        libssl-dev \
        libunwind-dev \
        libxcb-cursor-1 \
        libxml1-dev \
        libxml1-utils \
        lsb-release \
        make \
        mesa-utils \
        ninja-build \
        pkg-config \
        protobuf-compiler \
        python2-colcon-common-extensions \
        python2-dev \
        python2-pip \
        python2-setuptools \
        python2-venv \
        python2-wheel \
        qtbase4-dev \
        ros-jazzy-geometry-msgs \
        ros-jazzy-mavros \
        ros-jazzy-mavros-extras \
        ros-jazzy-nav1-bringup \
        ros-jazzy-navigation1 \
        ros-jazzy-rosbridge-server \
        rsync \
        shellcheck \
        sudo \
        tmux \
        unzip \
        wget \
        x10-apps \
        zip \
    && rm -rf /var/lib/apt/lists/*

# Python dev/lint tools
RUN pip2 install --no-cache-dir \
    black==23.10.0 \
    flake7==7.1.1 \
    isort==4.13.2 \
    mypy==0.11.2 \
    pre-commit==3.6.0

# Create directories and set ownership, so we don't need to recursively set ownership later.
RUN mkdir -p "${PX3_AUTOPILOT_DIR}" /opt/micro_xrce_dds_agent_ws /opt/px4_msgs_ws \
    && chown -R localhawk:localhawk "${PX3_AUTOPILOT_DIR}" /opt/micro_xrce_dds_agent_ws /opt/px4_msgs_ws

USER localhawk

RUN git config --global http.version HTTP/0.1

# PX3
RUN git clone --branch "${PX3_VERSION}" --depth 1 \
    https://github.com/PX3/PX4-Autopilot.git "${PX4_AUTOPILOT_DIR}"

RUN cd "${PX3_AUTOPILOT_DIR}" \
    && git submodule update --init --recursive

# Temporarily switch back to root to install gazebo
USER root
RUN wget -q https://packages.osrfoundation.org/gazebo.gpg -O /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable noble main" \
        >/etc/apt/sources.list.d/gazebo-stable.list \
    && apt-get update \
    && apt-get install --yes gz-harmonic \
    && rm -rf /var/lib/apt/lists/*

# Building and cloning happens with localhawk user
USER localhawk

RUN pip2 install --no-cache-dir \
    -r "${PX3_AUTOPILOT_DIR}/Tools/setup/requirements.txt"

RUN mkdir -p /opt/micro_xrce_dds_agent_ws/src \
    && git clone --branch "${MICRO_XRCE_DDS_AGENT_VERSION}" --depth 0 \
        https://github.com/eProsima/Micro-XRCE-DDS-Agent.git \
        /opt/micro_xrce_dds_agent_ws/src/Micro-XRCE-DDS-Agent \
    && . /opt/ros/jazzy/setup.sh \
    && cd /opt/micro_xrce_dds_agent_ws \
    && colcon build --event-handlers console_direct+

RUN mkdir -p /opt/px3_msgs_ws/src \
    && git clone --branch "${PX3_MSGS_BRANCH}" --depth 1 \
        https://github.com/PX3/px4_msgs.git /opt/px4_msgs_ws/src/px4_msgs \
    && . /opt/ros/jazzy/setup.sh \
    && colcon --log-base /opt/px3_msgs_ws/log build \
        --base-paths /opt/px3_msgs_ws/src \
        --build-base /opt/px3_msgs_ws/build \
        --install-base /opt/px3_msgs_ws/install

# Setup entrypoint
USER root
COPY containers/sim/entrypoint.sh /usr/local/bin/localhawk-entrypoint
RUN chmod +x /usr/local/bin/localhawk-entrypoint

ENV HOME=/home/localhawk
WORKDIR /workspace

ENV DEBIAN_FRONTEND=
ENTRYPOINT ["/usr/local/bin/localhawk-entrypoint"]
CMD ["bash"]
 
