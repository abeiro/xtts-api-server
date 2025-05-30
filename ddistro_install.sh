#!/bin/bash

cd /home/dwemer/xtts-api-server
python3 -m venv /home/dwemer/python-tts
source /home/dwemer/python-tts/bin/activate

echo "This will take a while so please wait."

# Ask user about GPU
read -p "Do you own a GT10XX series GPU? (yes/no): " gpu_answer
if [[ "$gpu_answer" =~ ^[Yy][Ee][Ss]$ || "$gpu_answer" =~ ^[Yy]$ ]]; then
    torch_url="https://download.pytorch.org/whl/nightly/cu118"
else
    torch_url="https://download.pytorch.org/whl/nightly/cu128"
fi

python3 -m pip install --upgrade pip wheel ninja virtualenv
pip install setuptools==68.1.2
pip install -r requirements.txt
pip uninstall -y torch torchaudio
pip install --pre -U torch torchaudio --index-url "$torch_url"
#pip install xtts-api-server #Fails

sed -i 's/checkpoint = load_fsspec(model_path, map_location=torch.device("cpu"))\["model"\]/checkpoint = load_fsspec(model_path, map_location=torch.device("cpu"), weights_only=False)["model"]/' /home/dwemer/python-tts/lib/python3.11/site-packages/TTS/tts/models/xtts.py

cp /home/dwemer/TheNarrator.wav speakers/TheNarrator.wav

source /home/dwemer/python-tts/bin/activate

./conf.sh

echo 
echo "This will start CHIM XTTS to download the selected model"
echo "Wait for the message 'Uvicorn running on http://0.0.0.0:8020 (Press CTRL+C to quit)'"
echo "Then close this window. Press ENTER to continue"
read

echo "please wait...."

python -m xtts_api_server --listen

echo "Press Enter"
