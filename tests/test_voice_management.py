import tempfile
import unittest
from pathlib import Path

from xtts_api_server.voice_management import delete_flat_voice, normalize_voice_id


class VoiceManagementTest(unittest.TestCase):
    def test_deletes_flat_uploaded_voice(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            voice = Path(temp_dir) / "sample.wav"
            voice.write_bytes(b"wav")

            removed = delete_flat_voice(temp_dir, "sample")

            self.assertEqual(removed, voice)
            self.assertFalse(voice.exists())

    def test_does_not_delete_multi_sample_directory(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            voice_dir = Path(temp_dir) / "sample"
            voice_dir.mkdir()
            (voice_dir / "one.wav").write_bytes(b"wav")

            self.assertIsNone(delete_flat_voice(temp_dir, "sample"))
            self.assertTrue(voice_dir.exists())

    def test_rejects_path_traversal(self):
        with self.assertRaises(ValueError):
            normalize_voice_id("../sample")


if __name__ == "__main__":
    unittest.main()
