#!/bin/bash

cd /home/dwemer/xtts-api-server
python3 -m venv /home/dwemer/python-tts
source /home/dwemer/python-tts/bin/activate

echo "This will take a while so please wait."

# Detect GPU generation and choose appropriate torch/torchaudio + CUDA tag
# Default to modern RTX (Ada and newer) stable cu124
cu_tag="cu124"
torch_ver="2.5.1"
torchaudio_ver="2.5.1"
torch_url="https://download.pytorch.org/whl/${cu_tag}"
use_nightly=0

# Try to detect compute capability via nvidia-smi; fall back to user prompt for 10-series
compute_cap=""
if command -v nvidia-smi >/dev/null 2>&1; then
    compute_cap=$(nvidia-smi --query-gpu=compute_cap --format=csv,noheader | head -n1 2>/dev/null | tr -d '\r')
fi

# If user has Pascal (GTX 10xx) fallback to CUDA 11.8 + torch 2.2.2
if [[ -z "$compute_cap" ]]; then
    read -p "Are you using a GTX 10xx (Pascal) GPU? (yes/no): " gpu_answer
    if [[ "$gpu_answer" =~ ^[Yy][Ee][Ss]$ || "$gpu_answer" =~ ^[Yy]$ ]]; then
        cu_tag="cu118"
        torch_url="https://download.pytorch.org/whl/${cu_tag}"
        torch_ver="2.2.2"
        torchaudio_ver="2.2.2"
    fi
else
    # Parse major.minor like 8.9 (Ada) or 9.0 (Hopper/Blackwell)
    cap_major=${compute_cap%%.*}
    cap_minor=${compute_cap#*.}
    # For 50xx Blackwell (compute capability >= 9), use nightly cu128 wheels
    if [[ "$cap_major" -ge 9 ]]; then
        cu_tag="cu128"
        torch_url="https://download.pytorch.org/whl/nightly/${cu_tag}"
        use_nightly=1
    # For older (<= 7.x Pascal/Turing), force cu118 + torch 2.2.2
    elif [[ "$cap_major" -le 7 ]]; then
        cu_tag="cu118"
        torch_url="https://download.pytorch.org/whl/${cu_tag}"
        torch_ver="2.2.2"
        torchaudio_ver="2.2.2"
    fi
fi

python3 -m pip install --upgrade pip wheel ninja virtualenv
pip install setuptools==68.1.2
# Install app requirements excluding torch/torchaudio/torchvision/triton and nvidia-cu12 split libs
# so our chosen CUDA wheels stay consistent
grep -viE '^(torch|torchaudio|torchvision|triton|nvidia-[a-z0-9-]+-cu[0-9]+)\b' requirements.txt > /tmp/requirements.no-torch.txt
pip install --no-deps -r /tmp/requirements.no-torch.txt
# Pin to stable, CUDA-tagged PyTorch/Torchaudio that do not require TorchCodec
pip cache purge || true
# Drop local caches that can interfere with extension/wheel resolution
rm -rf "$HOME/.cache/torch_extensions" "$HOME/.cache/torch" "$HOME/.cache/pip" 2>/dev/null || true
pip uninstall -y torch torchaudio torchcodec torchvision triton || true
if [[ "$use_nightly" -eq 1 ]]; then
    # Blackwell/50xx path: use nightly cu128 wheels, let dependencies resolve
    pip install --pre -U --no-cache-dir --index-url "$torch_url" torch torchaudio
else
    pip install --no-deps --no-cache-dir --index-url "$torch_url" "torch==${torch_ver}+${cu_tag}" "torchaudio==${torchaudio_ver}+${cu_tag}"
    # Install a Triton version that matches torch (skip for nightly)
    if [[ "${torch_ver}" == 2.2.* ]]; then
        pip install --no-cache-dir "triton==2.2.0"
    elif [[ "${torch_ver}" == 2.4.* ]]; then
        pip install --no-cache-dir "triton==3.0.0"
    else
        # torch 2.5.x
        pip install --no-cache-dir "triton==3.1.0"
    fi
fi
pip check || true
# Ensure fallback audio loader is available
pip install --no-cache-dir soundfile
# Verify critical versions and backend
python - <<'PY'
import sys
try:
    import torch, torchaudio
    print("torch:", torch.__version__)
    print("torchaudio:", torchaudio.__version__)
    try:
        import triton
        print("triton:", triton.__version__)
    except Exception as e:
        print("triton import error:", e)
    try:
        import torchcodec  # noqa: F401
        print("torchcodec: present (should be absent)")
    except Exception:
        print("torchcodec: not installed (OK)")
    try:
        print("audio_backend:", torchaudio.get_audio_backend())
    except Exception:
        print("audio_backend: unknown (OK)")
    try:
        if torch.cuda.is_available():
            d = torch.cuda.get_device_properties(0)
            print("cuda: available, device=", d.name, "cc=", f"{d.major}.{d.minor}")
        else:
            print("cuda: not available")
    except Exception as e:
        print("cuda check error:", e)
except Exception as e:
    print("xtts-preflight-error:", e)
    sys.exit(0)
PY
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
