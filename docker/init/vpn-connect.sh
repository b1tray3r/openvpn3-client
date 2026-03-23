#!/bin/bash

if [[ -z "$OVPN" || ! -f "$OVPN" ]]; then
    echo "Missing VPN profile" >&2
    exit 2
elif [ -e /dev/net/tun ]; then
    /opt/init/vpn-disconnect.sh
fi

if ! pgrep dbus-daemon >/dev/null 2>&1; then
    echo "Starting the DBUS daemon"
    /etc/init.d/dbus start
    sleep 2
    ts=$(date +%s)
    while :; do
        td=$(( $(date +%s) - $ts ))
        if ! netstat -a | grep 'LISTENING' | grep -q '/run/dbus/system_bus_socket'; then
            if [ $td -lt 10 ]; then
                sleep 0.2
                continue
            fi
            echo "Timed out waiting on DBUS" >&2
            exit 2
        fi
        break
    done
fi

# Create a TUN device
mkdir -p /dev/net 2>/dev/null
mknod /dev/net/tun c 10 200
chmod 0666 /dev/net/tun

echo "Connecting to remote server at $(grep -e '^remote ' "$OVPN" | awk '{print $2}')"

TOTP_CODE=""
if [[ -n "$TOTP_SECRET" ]]; then
    echo "Generating TOTP code..."
    TOTP_CODE=$(oathtool --totp -b "$TOTP_SECRET" 2>/dev/null)
    if [[ -z "$TOTP_CODE" ]]; then
        echo "Failed to generate TOTP" >&2
        exit 1
    fi
    echo "TOTP generated: $TOTP_CODE"
fi

CREDENTIALS=$(printf "%s\n%s\n%s\n%s\n" "$USERNAME" "$PASSWORD" "$TOTP_CODE" "$PRIVATE_KEY_PASSWORD")

echo "Starting VPN session with credentials..."

if ! echo "$CREDENTIALS" | openvpn3 session-start --config $OVPN --timeout 20 --persist-tun \
        || ! ip r | grep -qe '^0.0.0.0/1 '; then
    echo "Failed to connect to the VPN" >&2
    exit 1
fi

sleep 2

if [ -n "$DNS" ]; then
    echo "Configuring DNS information"

    # Update DNS
    cp /etc/resolv.conf /etc/resolv.conf-bak
    echo "" > /etc/resolv.conf

    for ip in $(echo $DNS | sed 's/,/ /'); do
        echo "nameserver $ip" >> /etc/resolv.conf
    done
fi

echo ""
echo "=== VPN DNS Configuration ==="
resolvectl status tun0 2>/dev/null || cat /etc/resolv.conf
echo "=============================="

