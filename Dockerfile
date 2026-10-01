FROM osrf/ros:jazzy-desktop-full

ARG PX4_VERSION=v1.17.0
ARG PX4_MSGS_BRANCH=release/1.17
ARG MICRO_XRCE_DDS_AGENT_VERSION=v2.4.3
ARG USERNAME=developer
ARG LOCAL_UID=1000
ARG LOCAL_GID=1000

ENV DEBIAN_FRONTEND=noninteractive
ENV PX4_AUTOPILOT_DIR=/opt/PX4-Autopilot
ENV ROS_DISTRO=jazzy
ENV GZ_VERSION=harmonic
ENV ROS_AUTOMATIC_DISCOVERY_RANGE=LOCALHOST
ENV GZ_IP=127.0.0.1
ENV PIP_BREAK_SYSTEM_PACKAGES=1
ENV USERNAME=${USERNAME}
ENV LOCAL_UID=${LOCAL_UID}
ENV LOCAL_GID=${LOCAL_GID}

# Gazebo (Harmonic) apt repo, matched to Jazzy/Ubuntu Noble
RUN apt-get update && apt-get install --yes ca-certificates gnupg wget \
    && rm -rf /var/lib/apt/lists/*
RUN wget -q https://packages.osrfoundation.org/gazebo.gpg -O /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable noble main" \
        >/etc/apt/sources.list.d/gazebo-stable.list

# Core tools, PX4 build deps, Gazebo, Micro XRCE-DDS Agent deps, ROS extras
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
        gstreamer1.0-gl \
        gstreamer1.0-libav \
        gstreamer1.0-plugins-bad \
        gstreamer1.0-plugins-base \
        gstreamer1.0-plugins-good \
        gstreamer1.0-plugins-ugly \
        gz-harmonic \
        lcov \
        libasio-dev \
        libeigen3-dev \
        libgl1 \
        libglx-mesa0 \
        libgstreamer1.0-dev \
        libgstreamer-plugins-base1.0-dev \
        libimage-exiftool-perl \
        libopencv-dev \
        libssl-dev \
        libtinyxml2-dev \
        libunwind-dev \
        libxcb-cursor0 \
        libxml2-dev \
        libxml2-utils \
        lsb-release \
        make \
        mesa-utils \
        ninja-build \
        pkg-config \
        protobuf-compiler \
        python3-colcon-common-extensions \
        python3-dev \
        python3-pip \
        python3-setuptools \
        python3-venv \
        python3-wheel \
        ros-jazzy-geometry-msgs \
        ros-jazzy-mavros \
        ros-jazzy-mavros-extras \
        ros-jazzy-nav2-bringup \
        ros-jazzy-navigation2 \
        ros-jazzy-ros-gz \
        ros-jazzy-rosbridge-server \
        rsync \
        shellcheck \
        sudo \
        tmux \
        unzip \
        wget \
        x11-apps \
        zip \
    && rm -rf /var/lib/apt/lists/*

# geographiclib datasets required by mavros/mavros-extras
RUN /opt/ros/jazzy/lib/mavros/install_geographiclib_datasets.sh

# Python dev/lint tools
RUN pip3 install --no-cache-dir \
    black==24.8.0 \
    flake8==7.1.1 \
    isort==5.13.2 \
    mypy==1.11.2 \
    pre-commit==3.8.0

# Non-root dev user, UID/GID matched to the host so bind-mounted files stay writable
RUN groupadd --non-unique --gid "${LOCAL_GID}" "${USERNAME}" \
    && useradd --non-unique --uid "${LOCAL_UID}" --gid "${LOCAL_GID}" --create-home --shell /bin/bash "${USERNAME}" \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

# Pre-create dirs owned by the dev user to avoid a recursive chown later.
RUN mkdir -p "${PX4_AUTOPILOT_DIR}" /opt/micro_xrce_dds_agent_ws /opt/px4_msgs_ws \
    && chown -R "${USERNAME}:${USERNAME}" "${PX4_AUTOPILOT_DIR}" /opt/micro_xrce_dds_agent_ws /opt/px4_msgs_ws

USER ${USERNAME}

RUN git config --global http.version HTTP/1.1

# PX4
RUN git clone --branch "${PX4_VERSION}" --depth 1 --recurse-submodules \
    https://github.com/PX4/PX4-Autopilot.git "${PX4_AUTOPILOT_DIR}"

RUN pip3 install --no-cache-dir \
    -r "${PX4_AUTOPILOT_DIR}/Tools/setup/requirements.txt"

# Prebuild SITL so `./stack sim` only launches it.
RUN cd "${PX4_AUTOPILOT_DIR}" \
    && make px4_sitl_default

# Micro XRCE-DDS Agent
RUN mkdir -p /opt/micro_xrce_dds_agent_ws/src \
    && git clone --branch "${MICRO_XRCE_DDS_AGENT_VERSION}" --depth 1 --recurse-submodules \
        https://github.com/eProsima/Micro-XRCE-DDS-Agent.git \
        /opt/micro_xrce_dds_agent_ws/src/Micro-XRCE-DDS-Agent \
    && . /opt/ros/jazzy/setup.sh \
    && cd /opt/micro_xrce_dds_agent_ws \
    && colcon build --event-handlers console_direct+

# px4_msgs (ROS 2 message definitions matching the PX4 version above)
RUN mkdir -p /opt/px4_msgs_ws/src \
    && git clone --branch "${PX4_MSGS_BRANCH}" --depth 1 \
        https://github.com/PX4/px4_msgs.git /opt/px4_msgs_ws/src/px4_msgs \
    && . /opt/ros/jazzy/setup.sh \
    && colcon --log-base /opt/px4_msgs_ws/log build \
        --base-paths /opt/px4_msgs_ws/src \
        --build-base /opt/px4_msgs_ws/build \
        --install-base /opt/px4_msgs_ws/install

# Setup entrypoint
USER root

# Cyclone DDS for ROS 2. Installed here so it doesn't invalidate the PX4 build cache.
RUN apt-get update && apt-get install --yes ros-jazzy-rmw-cyclonedds-cpp \
    && rm -rf /var/lib/apt/lists/*
ENV RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

# The real bashrc lives in the bind-mounted repo, so editing it needs no rebuild.
RUN echo '[[ -f /workspace/scripts/container/bashrc ]] && source /workspace/scripts/container/bashrc' \
    >/home/${USERNAME}/.bashrc
COPY scripts/container/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENV HOME=/home/${USERNAME}
WORKDIR /workspace

ENV DEBIAN_FRONTEND=
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash"]
