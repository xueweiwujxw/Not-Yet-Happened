import importlib.util
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location("production", Path(__file__).parents[1] / "scripts/build_mandarin_voice.py")
production = importlib.util.module_from_spec(spec)
spec.loader.exec_module(production)


class VoiceProductionTests(unittest.TestCase):
    def setUp(self):
        self.turn = {"speaker": "栞", "text": "有一根化了。"}
        self.turn["voice_key"] = production.sha256("栞\n有一根化了。".encode())
        self.cast = {"speakers": {"栞": {"voice": "zh-CN-XiaoxiaoNeural", "rate": "+0%"}}}

    def test_exact_speech_and_cast_are_preserved(self):
        result = production.recipe(self.turn, self.cast)
        self.assertEqual(result["text"], self.turn["text"])
        self.assertEqual(result["voice"], "zh-CN-XiaoxiaoNeural")

    def test_reject_stale_text(self):
        self.turn["text"] = "另一句话。"
        with self.assertRaises(ValueError):
            production.recipe(self.turn, self.cast)

    def test_reject_accidental_multilingual_default(self):
        self.cast["speakers"]["栞"]["voice"] = "en-US-EmmaMultilingualNeural"
        with self.assertRaises(ValueError):
            production.recipe(self.turn, self.cast)

    def test_reject_narration(self):
        self.turn["speaker"] = ""
        with self.assertRaises(ValueError):
            production.recipe(self.turn, self.cast)

    def test_changed_cast_invalidates_recipe(self):
        before = production.recipe(self.turn, self.cast)
        self.cast["speakers"]["栞"]["rate"] = "-4%"
        self.assertNotEqual(before, production.recipe(self.turn, self.cast))


class RetryTests(unittest.IsolatedAsyncioTestCase):
    async def test_transient_timeout_retries_with_bounded_backoff(self):
        calls, pauses = [], []
        async def request():
            calls.append(True)
            if len(calls) < 3:
                raise TimeoutError()
        async def delay(seconds):
            pauses.append(seconds)
        await production.synthesize_with_retry(request, delay)
        self.assertEqual(len(calls), 3)
        self.assertEqual(pauses, [2, 4])

    async def test_permanent_failure_stops_after_three_attempts(self):
        calls = []
        async def request():
            calls.append(True)
            raise TimeoutError()
        async def delay(_seconds):
            pass
        with self.assertRaisesRegex(RuntimeError, "3 attempts"):
            await production.synthesize_with_retry(request, delay)
        self.assertEqual(len(calls), 3)

    async def test_access_rejection_is_not_retried(self):
        class Rejected(Exception):
            status = 403
        calls = []
        async def request():
            calls.append(True)
            raise Rejected()
        with self.assertRaisesRegex(RuntimeError, "403"):
            await production.synthesize_with_retry(request)
        self.assertEqual(len(calls), 1)
