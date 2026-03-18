#!/usr/bin/env bash

export GGML_VK_PREFER_HOST_MEMORY=1

host=${1:-localhost}
port=${2:-8012}

llama-server \
    --host $host \
    --port $port \
    --models-dir ~/llms \
    --models-max 2 \
    --n-gpu-layers 99 \
    --threads 8 \
    --ctx-size 0 \
    --mlock \
    --flash-attn 1 \
    --chat-template-kwargs '{"enable_thinking":true}'
