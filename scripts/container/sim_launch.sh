#!/usr/bin/env bash
#
source /workspace/scripts/container/source.sh

set -euo pipefail

# Sim settings and PX4 params; exported so PX4 sees the PX4_PARAM_* vars.
set -a
source /workspace/config/sim.env
set +a

PX4_AUTOPILOT_DIR="${PX4_AUTOPILOT_DIR:-/opt/PX4-Autopilot}"
HEADLESS="${HEADLESS:-1}"
: "${PX4_MODEL:?PX4_MODEL must be set in config/sim.env}"
: "${MICRO_XRCE_AGENT_PORT:?MICRO_XRCE_AGENT_PORT must be set in config/sim.env}"

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
    (unset HEADLESS; make -C "${PX4_AUTOPILOT_DIR}" px4_sitl "${PX4_MODEL}") &
else
    HEADLESS=1 make -C "${PX4_AUTOPILOT_DIR}" px4_sitl "${PX4_MODEL}" &
fi
pids+=("$!")

wait -n "${pids[@]}"
