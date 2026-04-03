# Claude Code Container

Docker container to run Claude Code in an isolated environment, based on the [Anthropic reference devcontainer](https://github.com/anthropics/claude-code/tree/main/.devcontainer).

## Why run Claude Code in a container?

Anthropic recommends running Claude Code inside a container when using `--dangerously-skip-permissions` for unattended operation. The container provides filesystem isolation and network restrictions (firewall) that limit what Claude can access if something goes wrong. See the [official documentation](https://code.claude.com/docs/en/devcontainer) for more details.

This repo strips the devcontainer.json (VS Code integration) and provides a simple shell script to launch the container directly with Docker.

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

Once inside the container:

```bash
claude
```

## How it works

### Shared session history

Claude Code stores session history based on the absolute path of the project. The original devcontainer mounts everything under `/workspace`, which means sessions created inside the container are not visible when running Claude Code directly on the host (and vice versa).

To fix this, `claude-container.sh` mounts the project directory at the **same absolute path** inside the container (`-v "$PROJECT_DIR:$PROJECT_DIR"` + `-w "$PROJECT_DIR"`). This way Claude Code sees the exact same path in both environments, and session history is seamlessly shared between the host and the container.

### Bind mounts

| Host | Container | Purpose |
|------|-----------|---------|
| `$(pwd)` | `$(pwd)` | Project (same path = shared session history) |
| `~/.claude.json` | `/home/node/.claude.json` | Claude auth |
| `~/.claude` | `/home/node/.claude` | Claude Code config and sessions |
| `/run/user/$UID/bus` | `/run/user/1000/bus` | D-Bus socket (notifications) |

### Isolation caveats

This setup trades some isolation for convenience. Two things weaken the container boundary compared to a fully isolated devcontainer:

- **Claude config and credentials** (`~/.claude`, `~/.claude.json`) are shared from the host. A malicious process inside the container could read or exfiltrate these.
- **D-Bus session socket** is mounted for desktop notifications. This exposes the host's session bus, which in theory allows interaction with other D-Bus services (file manager, secret manager, etc.), not just notifications. To restrict exposure to notifications only, use `xdg-dbus-proxy` with a filter on `org.freedesktop.Notifications`.

For trusted repositories this is a reasonable tradeoff. For untrusted code, consider removing the D-Bus mount and using isolated credentials.

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
