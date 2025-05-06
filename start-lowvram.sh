#!/bin/bash

cd /home/dwemer/xtts-api-server/

source /home/dwemer/python-tts/bin/activate

date > log.txt

python -m xtts_api_server --listen --lowvram &>> log.txt &



