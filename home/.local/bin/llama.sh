#!/usr/bin/env bash

export GGML_VK_PREFER_HOST_MEMORY=1

host=${1:-localhost}
port=${2:-8012}

llama-server \
    --host $host \
    --port $port \
    --models-preset ~/.config/llama.ini \
    --models-dir ~/llms \
    --models-max 2 \
    --threads 8
