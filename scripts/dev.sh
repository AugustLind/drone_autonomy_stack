#!/usr/bin/env bash
#
# Build, start, and launch the sim_image dev container via Docker Compose.
#
# Usage:
#   ./scripts/dev.sh build   # build the sim image
#   ./scripts/dev.sh up      # create/start sim_container, repo bind-mounted at /workspace
#   ./scripts/dev.sh shell   # open a shell in sim_container
#   ./scripts/dev.sh sim     # run scripts/container/sim_launch.sh inside sim_container
#   ./scripts/dev.sh gpu     # print the detected GPU mode (nvidia|dri|none)
#   ./scripts/dev.sh down    # stop and remove sim_container

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE_COMPOSE="${REPO_ROOT}/config/compose.yaml"

export LOCAL_UID="${LOCAL_UID:-$(id -u)}"
export LOCAL_GID="${LOCAL_GID:-$(id -g)}"
# Note: intentionally not named USERNAME - many shells/systems already
# export that as the host login name, which would collide with the
# in-container dev user name used below.
CONTAINER_USERNAME="developer"

usage() {
    cat <<EOF
Usage: $(basename "$0") <build|up|shell|sim|gpu|down>

  build  build the sim image
  up     create (or resume) sim_container, bind-mounting the repo at /workspace,
         and grant it local X11 access (xhost +local:docker)
  shell  open an interactive shell in sim_container
  sim    run scripts/container/sim_launch.sh inside sim_container; HEADLESS=0 for a GUI,
         e.g. HEADLESS=0 ./scripts/dev.sh sim
  gpu    print the detected GPU mode (nvidia|dri|none) and exit
  down   stop and remove sim_container

GPU acceleration is auto-detected: nvidia (if nvidia-smi works and Docker
exposes the NVIDIA runtime), else dri (if /dev/dri exists, for Intel/AMD),
else software rendering (slow). Override with SIM_GPU=nvidia|dri|none.
GPU access is assigned when the container is created, so run 'down' then
'up' again after changing GPU mode.
EOF
}

host_group_gid() {
    local group_name="$1"
    local fallback="$2"
    getent group "$group_name" | cut -d: -f3 || printf '%s\n' "$fallback"
}

select_gpu_mode() {
    local requested="${SIM_GPU:-auto}"

    case "$requested" in
        auto)
            if command -v nvidia-smi >/dev/null 2>&1 \
                && nvidia-smi >/dev/null 2>&1 \
                && docker info --format '{{json .Runtimes}}' 2>/dev/null \
                    | grep -qi nvidia; then
                printf '%s\n' nvidia
            elif [[ -d /dev/dri ]]; then
                printf '%s\n' dri
            else
                printf '%s\n' none
            fi
            ;;
        nvidia|dri|none)
            printf '%s\n' "$requested"
            ;;
        *)
            echo "SIM_GPU must be auto, nvidia, dri, or none" >&2
            exit 2
            ;;
    esac
}

gpu_mode="$(select_gpu_mode)"
compose=(docker compose --project-name drone_autonomy_stack -f "$BASE_COMPOSE")

case "$gpu_mode" in
    nvidia)
        export LOCAL_VIDEO_GID="${LOCAL_VIDEO_GID:-$(host_group_gid video 44)}"
        export LOCAL_RENDER_GID="${LOCAL_RENDER_GID:-$(host_group_gid render 109)}"
        compose+=(-f "${REPO_ROOT}/config/compose.nvidia.yaml")
        ;;
    dri)
        export LOCAL_VIDEO_GID="${LOCAL_VIDEO_GID:-$(host_group_gid video 44)}"
        export LOCAL_RENDER_GID="${LOCAL_RENDER_GID:-$(host_group_gid render 109)}"
        compose+=(-f "${REPO_ROOT}/config/compose.dri.yaml")
        ;;
esac

case "${1:-}" in
    build)
        "${compose[@]}" build
        ;;
    up)
        xhost +local:docker >/dev/null 2>&1 \
            || echo "warning: 'xhost +local:docker' failed; the container may not be able to open X11 windows" >&2
        echo "Starting simulator with GPU mode: ${gpu_mode}"
        if [[ "$gpu_mode" == none ]]; then
            echo "warning: no supported GPU runtime detected; Gazebo will use software rendering (slow)." >&2
        fi
        "${compose[@]}" up -d
        ;;
    shell)
        "${compose[@]}" exec --user "$CONTAINER_USERNAME" sim bash -i
        ;;
    sim)
        "${compose[@]}" exec --user "$CONTAINER_USERNAME" --env HEADLESS="${HEADLESS:-1}" sim /workspace/scripts/container/sim_launch.sh
        ;;
    gpu)
        echo "$gpu_mode"
        ;;
    down)
        "${compose[@]}" down
        ;;
    *)
        usage; exit 1
        ;;
esac
