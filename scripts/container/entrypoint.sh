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

# The px4-build volume may be created root-owned.
mkdir -p /opt/PX4-Autopilot/build
chown "${USERNAME}:${USERNAME}" /opt/PX4-Autopilot/build

# Match the host's video/render GIDs so Gazebo can use /dev/dri instead of llvmpipe.
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
