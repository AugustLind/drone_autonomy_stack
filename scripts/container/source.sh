#!/usr/bin/env bash

source /opt/ros/jazzy/setup.bash
source /opt/micro_xrce_dds_agent_ws/install/setup.bash
source /opt/px4_msgs_ws/install/setup.bash

export COLCON_DEFAULTS_FILE=/workspace/config/colcon_defaults.yaml

if [[ -f /workspace/install/setup.bash ]]; then
    source /workspace/install/setup.bash
fi
