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

# Check if credentials are provided
if [[ -z "$VPN_USERNAME" || -z "$VPN_PASSWORD" ]]; then
    echo "ERROR: VPN_USERNAME and VPN_PASSWORD must be set" >&2
    exit 1
fi

TOTP_CODE=""
if [[ -n "$VPN_TOTP_SECRET" ]]; then
    echo "Generating TOTP code..."
    TOTP_CODE=$(oathtool --totp -b "$VPN_TOTP_SECRET" 2>/dev/null)
    if [[ -z "$TOTP_CODE" ]]; then
        echo "Failed to generate TOTP" >&2
        exit 1
    fi
    echo "TOTP generated: $TOTP_CODE"
fi

echo "Starting VPN session with credentials..."

# Create credentials file for openvpn3
CRED_FILE=$(mktemp)
trap "rm -f $CRED_FILE" EXIT

{
    echo "$VPN_USERNAME"
    echo "$VPN_PASSWORD"
    [[ -n "$TOTP_CODE" ]] && echo "$TOTP_CODE"
    [[ -n "$VPN_PRIVATE_KEY_PASSWORD" ]] && echo "$VPN_PRIVATE_KEY_PASSWORD"
} > "$CRED_FILE"

if ! cat "$CRED_FILE" | openvpn3 session-start --config $OVPN --timeout 20 --persist-tun \
        || ! ip r | grep -qe '^0.0.0.0/1 '; then
    echo "Failed to connect to the VPN" >&2
    rm -f "$CRED_FILE"
    exit 1
fi

rm -f "$CRED_FILE"

sleep 2

if [ -n "$VPN_DNS" ]; then
    echo "Configuring DNS information"

    # Prepend VPN DNS servers to resolv.conf (before Docker's DNS)
    cp /etc/resolv.conf /etc/resolv.conf.bak
    
    # Build new resolv.conf with VPN DNS first
    {
        echo "# VPN DNS servers"
        for ip in $(echo $VPN_DNS | sed 's/,/ /'); do
            echo "nameserver $ip"
        done
        echo ""
        echo "# Original Docker DNS"
        cat /etc/resolv.conf.bak
    } > /etc/resolv.conf
fi

echo ""
echo "=== VPN DNS Configuration ==="
resolvectl status tun0 2>/dev/null || cat /etc/resolv.conf
echo "=============================="

