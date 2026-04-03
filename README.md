# Claude Code Container

Isolated Docker container to run Claude Code, based on the Anthropic reference setup.

## Contents

- `Dockerfile` - Image based on Node.js 20 with Claude Code, ZSH, git-delta, firewall
- `init-firewall.sh` - Restrictive iptables/ipset rules (outbound whitelist only)
- `claude-container.sh` - Wrapper script to quickly launch the container

## Prerequisites

- Docker
- A Claude account (claude.ai)
- `libnotify` on the host (optional, for desktop notifications)

## Build

```bash
docker build -t claude-code:latest .
```

## Usage

```bash
cd ~/my-project
./claude-container.sh
```

The script mounts the current directory at the same path inside the container, allowing Claude Code to share session history between the host and the container.

Once inside the container:

```bash
claude
```

## How it works

### Bind mounts

| Host | Container | Purpose |
|------|-----------|---------|
| `$(pwd)` | `$(pwd)` | Project (same path = shared session history) |
| `~/.claude.json` | `/home/node/.claude.json` | Claude auth |
| `~/.claude` | `/home/node/.claude` | Claude Code config and sessions |
| `/run/user/$UID/bus` | `/run/user/1000/bus` | D-Bus socket (notifications) |

### Desktop notifications

The host's D-Bus session socket is mounted into the container, allowing `notify-send` to send notifications to the host desktop. `libnotify-bin` is installed in the image.

> **Note**: mounting the D-Bus socket exposes the host's session bus to the container. To restrict exposure to notifications only, use `xdg-dbus-proxy` with a filter on `org.freedesktop.Notifications`.

### Firewall

The container ships with a firewall script (`init-firewall.sh`) that enforces a default-deny policy and only allows required domains: npm registry, GitHub, Anthropic API, Sentry, Statsig, VS Code marketplace.

To enable the firewall inside the container:

```bash
sudo /usr/local/bin/init-firewall.sh
```

> **Note**: the firewall requires `--cap-add=NET_ADMIN --cap-add=NET_RAW` at container launch. Add these flags to `claude-container.sh` if needed.

## Customization

### Adding domains to the firewall

Edit the `for domain in ...` loop in `init-firewall.sh`.
