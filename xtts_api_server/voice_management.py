import re
from pathlib import Path


VOICE_ID_PATTERN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_.-]{0,127}$")


def normalize_voice_id(value: str) -> str:
    voice_id = str(value or "").strip()
    if voice_id.lower().endswith(".wav"):
        voice_id = voice_id[:-4]
    if "/" in voice_id or "\\" in voice_id or not VOICE_ID_PATTERN.fullmatch(voice_id):
        raise ValueError("Voice ID must use only letters, numbers, dot, dash, or underscore.")
    return voice_id


def flat_voice_path(speaker_folder: str | Path, voice_id: str) -> Path:
    return Path(speaker_folder) / f"{normalize_voice_id(voice_id)}.wav"


def delete_flat_voice(speaker_folder: str | Path, voice_id: str) -> Path | None:
    path = flat_voice_path(speaker_folder, voice_id)
    if not path.is_file():
        return None
    path.unlink()
    return path
