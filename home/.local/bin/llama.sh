#!/usr/bin/env bash

export GGML_VK_PREFER_HOST_MEMORY=1

host=${1:-localhost}
port=${2:-8012}

systemd-run --user --scope -p MemoryMax=25G llama-server \
    --host $host \
    --port $port \
    --models-preset ~/.config/llama.cpp/presets.ini \
    --models-dir ~/models \
    --models-max 2 \
    --load-mode none \
    --threads 4
