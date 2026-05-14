#!/bin/bash
# claude-dev.sh

PROJECT_DIR=$(pwd)
echo $PROJECT_DIR
docker run -it --rm \
  -v "$PROJECT_DIR:$PROJECT_DIR" \
  -w "$PROJECT_DIR" \
  -v ~/.claude.json:/home/node/.claude.json \
  -v ~/.claude:/home/node/.claude \
  -v /run/user/$(id -u)/bus:/run/user/1000/bus \
  -e DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
  -e ANTHROPIC_MODEL=claude-opus-4-6 \
  claude-code:latest bash
