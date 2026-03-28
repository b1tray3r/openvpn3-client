# VPN

Docker-based OpenVPN 3 client with TOTP authentication.

## Prerequisites

- Docker
- `just` (optional, for convenience commands)

## Setup

1. Copy the environment template:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and fill in your credentials:
   - `VPN_USERNAME` - VPN username
   - `VPN_PASSWORD` - VPN password
   - `VPN_PRIVATE_KEY_PASSWORD` - Private key password (if applicable)
   - `VPN_TOTP_SECRET` - TOTP secret for 2FA (base32 encoded)
   - `VPN_DNS` - VPN DNS servers (comma-separated)

3. Place your OpenVPN config as `config.ovpn`

## Usage

```bash
# Build the image
just build

# Start VPN
just start

# Stop VPN
just stop
```

Or with Docker Compose:
```bash
docker compose up -d --build
docker compose down
```

## Requirements

- `/dev/net/tun` device must be available on the host
- `NET_ADMIN` capability required for the container

## Credits

https://github.com/dbergloev/docker-openvpn3/blob/main/init/vpn-connect.sh