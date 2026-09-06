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

exec gosu "${USERNAME}" "$@"
