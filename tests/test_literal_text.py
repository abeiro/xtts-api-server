import ast
import asyncio
import os
import tempfile
import types
import unittest
from datetime import datetime
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent.parent / "xtts_api_server"
SENTINEL = "XTTS-LITERAL-TEXT-SENTINEL"


def _load_function(path, name, namespace):
    # Compile one function from source without importing torch/TTS/fastapi.
    tree = ast.parse(path.read_text(encoding="utf-8"))
    node = next(n for n in ast.walk(tree)
                if isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef)) and n.name == name)
    node.decorator_list = []
    for arg in node.args.args:
        arg.annotation = None
    exec(compile(ast.Module([node], []), str(path), "exec"), namespace)
    return namespace[name]


class _FakeXTTS:
    model_source = "local"
    enable_cache_results = False
    output_folder = "out"

    def __init__(self):
        self.generated = []

    def get_speaker_wav(self, name):
        return name

    def clean_text(self, text):
        return text

    def check_cache(self, params):
        return None

    def switch_model_device(self):
        pass

    def update_cache(self, params, output_file):
        pass

    def local_generation(self, text, speaker_name, speaker_wav, language, output_file):
        self.generated.append(text)


_FakeXTTS.process_tts_to_file = _load_function(
    PACKAGE / "tts_funcs.py", "process_tts_to_file", {"os": os, "datetime": datetime})


class LiteralTextTest(unittest.TestCase):
    def setUp(self):
        self.xtts = _FakeXTTS()
        temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(temp_dir.cleanup)
        self.path = os.path.join(temp_dir.name, "sentinel.txt")
        Path(self.path).write_text(SENTINEL, encoding="utf-8")

    def test_tts_to_file_route_voices_txt_path_literally(self):
        noop = types.SimpleNamespace(info=lambda *a, **k: None, error=lambda *a, **k: None)
        route = _load_function(PACKAGE / "server.py", "tts_to_file", {
            "XTTS": self.xtts, "supported_languages": {"en"},
            "logger": noop, "HTTPException": Exception,
        })
        request = types.SimpleNamespace(
            text=self.path, speaker_wav="sample", language="en", file_name_or_path="out.wav")
        asyncio.run(route(request))
        self.assertEqual(self.xtts.generated, [self.path])

    def test_local_caller_can_opt_in_to_txt_file(self):
        self.xtts.process_tts_to_file(self.path, "sample", "en", allow_text_file=True)
        self.assertEqual(self.xtts.generated, [SENTINEL])

    def test_http_routes_never_opt_in(self):
        tree = ast.parse((PACKAGE / "server.py").read_text(encoding="utf-8"))
        calls = [n for n in ast.walk(tree) if isinstance(n, ast.Call)
                 and getattr(n.func, "attr", None) == "process_tts_to_file"]
        self.assertEqual(len(calls), 3)
        for call in calls:
            self.assertNotIn("allow_text_file", [k.arg for k in call.keywords])


if __name__ == "__main__":
    unittest.main()
