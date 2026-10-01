#!/usr/bin/env bash

source /workspace/scripts/container/source.sh

set -euo pipefail

ros2 launch bringup drone.launch.py "$@"
