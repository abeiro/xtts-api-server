#!/bin/bash

cd /home/dwemer/xtts-api-server/

source /home/dwemer/python-tts/bin/activate

python -m xtts_api_server --deepspeed --listen &> log.txt &



