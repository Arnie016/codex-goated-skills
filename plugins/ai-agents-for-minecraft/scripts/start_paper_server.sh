#!/bin/sh
set -eu

SERVER_DIR="${1:-${MINECRAFT_SERVER_DIR:-}}"

if [ -z "$SERVER_DIR" ]; then
  echo "Usage: start_paper_server.sh <server-dir>"
  exit 1
fi

cd "$SERVER_DIR"

if [ -x "./start-paper.sh" ]; then
  exec ./start-paper.sh
fi

if [ -x "./start-server.sh" ]; then
  exec ./start-server.sh
fi

echo "No start-paper.sh or start-server.sh found in $SERVER_DIR"
exit 1
