#!/bin/bash

# Add CUDA to PATH if the directory exists (matches deepspeed launcher)
if [ -d "/usr/local/cuda-12.8/bin" ]; then
  export PATH="/usr/local/cuda-12.8/bin:$PATH"
fi

cd /home/dwemer/xtts-api-server/

source /home/dwemer/python-tts/bin/activate

date > log.txt

python -m xtts_api_server --listen --lowvram &>> log.txt &



