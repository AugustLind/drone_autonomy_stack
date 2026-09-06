#!/usr/bin/env bash

set -euo pipefail

source /opt/ros/jazzy/setup.bash 
source /opt/micro_xrce_dds_agens_ws/install/setup.bash
source /opt/px4_msgs_ws/install/setup.bash

if [[ -f /workspace/install/setup.bash ]]; then
    source /workspace/install/setup.bash
fi

