#!/usr/bin/env bash

set -euo pipefail

USERNAME="${USERNAME:-developer}"
LOCAL_UID="${LOCAL_UID:-1000}"
LOCAL_GID="${LOCAL_GID:-1000}"

CURRENT_UID="$(id -u "${USERNAME}")"
CURRENT_GID="$(id -g "${USERNAME}")"

if [[ "${CURRENT_GID}" != "${LOCAL_GID}" ]]; then
    groupmod --non-unique --gid "${LOCAL_GID}" "${USERNAME}"
fi

if [[ "${CURRENT_UID}" != "${LOCAL_UID}" ]]; then
    usermod --non-unique --uid "${LOCAL_UID}" "${USERNAME}"
fi

chown -R "${LOCAL_UID}:${LOCAL_GID}" "/home/${USERNAME}"

# The px4-build named volume mounted over the PX4 build dir may come up
# owned by root on first creation; the dev user needs write access to it.
mkdir -p /opt/PX4-Autopilot/build
chown "${USERNAME}:${USERNAME}" /opt/PX4-Autopilot/build

# GPU passthrough (scripts/compose.dri.yaml / compose.nvidia.yaml) bind-mounts
# /dev/dri using the host's video/render group IDs, which won't already exist
# as named groups in the image - create/match them and add the dev user so
# Gazebo can actually use the device nodes instead of falling back to llvmpipe.
ensure_device_group() {
    local gid="$1"
    local preferred_name="$2"
    local group_name

    group_name="$(getent group "${gid}" | cut -d: -f1 || true)"
    if [[ -z "${group_name}" ]]; then
        group_name="${preferred_name}"
        if getent group "${group_name}" >/dev/null; then
            group_name="${preferred_name}-${gid}"
        fi
        groupadd --gid "${gid}" "${group_name}"
    fi

    usermod --append --groups "${group_name}" "${USERNAME}"
}

configure_drm_devices() {
    local device

    if [[ -n "${LOCAL_VIDEO_GID:-}" ]]; then
        ensure_device_group "${LOCAL_VIDEO_GID}" video
        for device in /dev/dri/card*; do
            [[ -e "${device}" ]] || continue
            chgrp "${LOCAL_VIDEO_GID}" "${device}"
            chmod g+rw "${device}"
        done
    fi

    if [[ -n "${LOCAL_RENDER_GID:-}" ]]; then
        ensure_device_group "${LOCAL_RENDER_GID}" render
        for device in /dev/dri/renderD*; do
            [[ -e "${device}" ]] || continue
            chgrp "${LOCAL_RENDER_GID}" "${device}"
            chmod g+rw "${device}"
        done
    fi
}

configure_drm_devices

exec gosu "${USERNAME}" "$@"
