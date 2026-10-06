#!/usr/bin/env bash

export GGML_VK_PREFER_HOST_MEMORY=1

host=${1:-localhost}
port=${2:-8012}

# A transient unit with a fixed name stays loaded after stop/failure
# (especially after oom-kill), so a plain systemd-run fails with
# "already loaded or has a fragment file".
# Reuse the loaded unit when it exists; only systemd-run when unknown.
if systemctl --user cat llama-server &>/dev/null; then
    if systemctl --user is-active --quiet llama-server; then
        echo "llama-server already running"
        exit 0
    fi
    systemctl --user reset-failed llama-server 2>/dev/null || true
    exec systemctl --user restart llama-server
fi

exec systemd-run \
    --user \
    --collect \
    --unit=llama-server \
    -p MemoryMax=25G \
    -p StandardOutput=journal \
    -p StandardError=journal \
    llama-server \
    --host "$host" \
    --port "$port" \
    --models-preset ~/.config/llama.cpp/presets.ini \
    --models-dir ~/models \
    --models-max 2 \
    --threads 12
