#!/bin/bash
# Add CUDA to PATH (detect highest installed cuda-*/bin)
cuda_bin=""
if [ -d "/usr/local" ]; then
  cuda_bin=$(ls -d /usr/local/cuda-*/bin 2>/dev/null | sort -V | tail -n1)
fi
if [ -n "$cuda_bin" ] && [ -d "$cuda_bin" ]; then
  export PATH="$cuda_bin:$PATH"
fi

cd /home/dwemer/xtts-api-server/

source /home/dwemer/python-tts/bin/activate

python -m xtts_api_server --deepspeed --listen &> log.txt &



