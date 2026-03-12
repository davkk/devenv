#!/usr/bin/env bash

export GGML_VK_PREFER_HOST_MEMORY=1

host=${1:-localhost}
port=${2:-8012}

llama-server \
    --host $host \
    --port $port \
    --models-dir ~/llms \
    --n-gpu-layers 99 \
    --ctx-size 0 \
    --flash-attn 1
