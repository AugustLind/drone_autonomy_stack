#!/usr/bin/env bash
#
source /workspace/scripts/container/source.sh

set -euo pipefail

ros2 service call /fsm_node/start_search drone_interface/srv/StartSearch "{corners: [{x: 0.0, y: 0.0}, {x: 0.0, y: 20.0}, {x: 20.0, y: 0.0}, {x: 20.0, y: 20.0}], swath_width: 4.0, altitude: 10.0}"
