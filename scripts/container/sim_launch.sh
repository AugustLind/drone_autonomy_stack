#!/usr/bin/env bash
#
source /workspace/scripts/container/source.sh

set -euo pipefail

PX4_AUTOPILOT_DIR="${PX4_AUTOPILOT_DIR:-/opt/PX4-Autopilot}"
PX4_MODEL="${PX4_MODEL:-gz_x500}"
MICRO_XRCE_AGENT_PORT="${MICRO_XRCE_AGENT_PORT:-8888}"
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

export PX4_PARAM_COM_RC_IN_MODE=4

MicroXRCEAgent udp4 -p "${MICRO_XRCE_AGENT_PORT}" &
pids+=("$!")

if [[ "${HEADLESS}" == "0" ]]; then
    (unset HEADLESS; make -C "${PX4_AUTOPILOT_DIR}" px4_sitl "${PX4_MODEL}") &
else
    HEADLESS=1 make -C "${PX4_AUTOPILOT_DIR}" px4_sitl "${PX4_MODEL}" &
fi
pids+=("$!")

wait -n "${pids[@]}"
