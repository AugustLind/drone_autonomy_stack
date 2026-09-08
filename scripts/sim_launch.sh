#!/usr/bin/env bash
#
# Starts the Micro XRCE-DDS Agent and PX4 SITL (Gazebo) for a single drone.
# No ROS 2 involvement at this stage - just the sim + the agent PX4's SITL
# will connect its uXRCE-DDS client to.

source /workspace/scripts/source.sh

set -euo pipefail

PX4_AUTOPILOT_DIR="${PX4_AUTOPILOT_DIR:-/opt/PX4-Autopilot}"
PX4_MODEL="${PX4_MODEL:-gz_x500}"
MICRO_XRCE_AGENT_PORT="${MICRO_XRCE_AGENT_PORT:-8888}"
# PX4's gz init script (px4-rc.gzsim) only checks whether HEADLESS is set at
# all, not its value - any non-empty value (including "0") suppresses the
# gz gui. So HEADLESS must be left unset in the child environment to get a
# gui, and default here to headless (1) unless the caller explicitly asked
# for "0".
HEADLESS="${HEADLESS:-1}"

pids=()

cleanup() {
    trap - INT TERM EXIT
    if ((${#pids[@]})); then
        kill "${pids[@]}" 2>/dev/null || true
        wait "${pids[@]}" 2>/dev/null || true
    fi
}
trap cleanup INT TERM EXIT

MicroXRCEAgent udp4 -p "${MICRO_XRCE_AGENT_PORT}" &
pids+=("$!")

if [[ "${HEADLESS}" == "0" ]]; then
    # HEADLESS may already be exported (e.g. by `docker exec -e HEADLESS=0`),
    # so it must be explicitly unset here, not just left unprefixed - a bare
    # `make ...` would still inherit it from the parent environment.
    (unset HEADLESS; make -C "${PX4_AUTOPILOT_DIR}" px4_sitl "${PX4_MODEL}") &
else
    HEADLESS=1 make -C "${PX4_AUTOPILOT_DIR}" px4_sitl "${PX4_MODEL}" &
fi
pids+=("$!")

wait -n "${pids[@]}"
