#!/bin/bash

cd /home/dwemer/xtts-api-server
python3 -m venv /home/dwemer/python-tts
source /home/dwemer/python-tts/bin/activate

echo "This will take a while so please wait."

# Ask user about GPU
read -p "Are you using a GT10XX series GPU? (yes/no): " gpu_answer
if [[ "$gpu_answer" =~ ^[Yy][Ee][Ss]$ || "$gpu_answer" =~ ^[Yy]$ ]]; then
    cu_tag="cu118"
    torch_url="https://download.pytorch.org/whl/${cu_tag}"
    torch_ver="2.2.2"
    torchaudio_ver="2.2.2"
    python3 -m pip install --upgrade pip wheel ninja virtualenv
    pip install setuptools==68.1.2
    # Install app requirements without auto-pulling torch/torchaudio from deps
    pip install --no-deps -r requirements.txt
    # Pin to stable, CUDA-tagged PyTorch/Torchaudio that do not require TorchCodec
    pip cache purge || true
    pip uninstall -y torch torchaudio torchcodec torchvision || true
    pip install --no-deps --no-cache-dir --index-url "$torch_url" "torch==${torch_ver}+${cu_tag}" "torchaudio==${torchaudio_ver}+${cu_tag}"
    pip check || true
    # Ensure fallback audio loader is available
    pip install --no-cache-dir soundfile
    sed -i 's/checkpoint = load_fsspec(model_path, map_location=torch.device("cpu"))\["model"\]/checkpoint = load_fsspec(model_path, map_location=torch.device("cpu"), weights_only=False)["model"]/' /home/dwemer/python-tts/lib/python3.11/site-packages/TTS/tts/models/xtts.py

else
    read -p "New: Use CUDA13. Needs windows updated drivers. RTX 50XX should use this. Usey cuda13? (yes/no): " gpu5_answer
    if [[ "$gpu5_answer" =~ ^[Yy][Ee][Ss]$ || "$gpu5_answer" =~ ^[Yy]$ ]]; then
	    cu_tag="cu130"
	    torch_url="https://download.pytorch.org/whl/${cu_tag}"
	    echo "Using torch: $torch_url"
	    python3 -m pip install --upgrade pip wheel ninja virtualenv
	    pip install setuptools==68.1.2
	    # Install app requirements without auto-pulling torch/torchaudio from deps
	    #pip install --no-deps -r requirements5.txt  --index-url=$torch_url
	    pip install -r requirements5.txt  --extra-index-url=https://download.pytorch.org/whl/cu130
	    # Pin to stable, CUDA-tagged PyTorch/Torchaudio that do not require TorchCodec
	    pip check || true
	    # Ensure fallback audio loader is available
	    pip install --no-cache-dir soundfile
	    #pip install xtts-api-server #Fails

    else
	    cu_tag="cu128"
	    torch_url="https://download.pytorch.org/whl/${cu_tag}"
	    echo "Using torch: $torch_url"
	    python3 -m pip install --upgrade pip wheel ninja virtualenv
	    pip install setuptools==68.1.2
	    # Install app requirements without auto-pulling torch/torchaudio from deps
	    pip install --no-deps -r requirements.txt
	    # Pin to stable, CUDA-tagged PyTorch/Torchaudio that do not require TorchCodec
	    pip cache purge || true
	    pip uninstall -y torch torchaudio torchcodec torchvision || true
	    #pip install --index-url "$torch_url" torch torchaudio torchcodec torchvision 
	    pip install torch==2.7.0+cu128 torchaudio==2.7.0+cu128 torchvision==0.22.0+cu128 --index-url=https://download.pytorch.org/whl/
	    pip check || true
	    # Ensure fallback audio loader is available
	    pip install --no-cache-dir soundfile
	    #pip install xtts-api-server #Fails
	    sed -i 's/checkpoint = load_fsspec(model_path, map_location=torch.device("cpu"))\["model"\]/checkpoint = load_fsspec(model_path, map_location=torch.device("cpu"), weights_only=False)["model"]/' /home/dwemer/python-tts/lib/python3.11/site-packages/TTS/tts/models/xtts.py

    fi
fi


cp /home/dwemer/TheNarrator.wav speakers/TheNarrator.wav

source /home/dwemer/python-tts/bin/activate

./conf.sh

echo 
echo "This will start CHIM XTTS to download the selected model"
echo "Wait for the message 'Uvicorn running on http://0.0.0.0:8020 (Press CTRL+C to quit)'"
echo "Then close this window. Press ENTER to continue"
read

echo "please wait...."

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/dwemer/python-tts/lib/python3.11/site-packages/nvidia/cu13/lib/

python -m xtts_api_server --listen

echo "Press Enter"
