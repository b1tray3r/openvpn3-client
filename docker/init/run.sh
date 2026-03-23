#!/bin/bash

set -e

echo "Launching OpenVPN at $(date +'%Y-%m-%d %H:%M')"

usermod -u $PUID docker_user 2>/dev/null
groupmod -g $PGID docker_group 2>/dev/null
chown -R docker_user:docker_group /app

if ! /opt/init/vpn-connect.sh; then
    exit 1
fi

trap '/opt/init/vpn-disconnect.sh; exit 0' SIGTERM SIGINT SIGHUP

echo "VPN connected, running..."

tail -f /dev/null