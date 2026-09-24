#!/usr/bin/env python3
"""Offline audition production. Runtime/CI do not contact a speech provider.

Requires edge-tts==7.2.8 and ffmpeg/ffprobe. Run export_voice_turns.gd first.
Each request contains only one authored speech turn; no character labels or narration.
Candidate assets stay in build/voice/candidate until explicitly copied after review.
"""
import argparse
import asyncio
import hashlib
import importlib.metadata
import json
import os
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
PRODUCTION = {"encoding": "mono 24 kHz Ogg Vorbis q5", "filter": "loudnorm=I=-20:TP=-2:LRA=11"}


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def recipe(turn, casting):
    if not turn["speaker"] or not turn["text"].strip():
        raise ValueError("Narration/empty turns cannot be synthesized")
    expected = sha256((turn["speaker"] + "\n" + turn["text"]).encode())
    if turn["voice_key"] != expected:
        raise ValueError("Stale speech key")
    choice = casting["speakers"][turn["speaker"]]
    if not choice["voice"].startswith("zh-CN-"):
        raise ValueError("Mandarin production requires an explicit zh-CN voice")
    return {"key": expected, "speaker": turn["speaker"], "text": turn["text"],
            "voice": choice["voice"], "rate": choice["rate"], "production": PRODUCTION,
            "edge_tts_version": "7.2.8"}


async def synthesize_with_retry(request, delay=asyncio.sleep, connection_errors=(TimeoutError, OSError)):
    for attempt in range(3):
        try:
            await request()
            return
        except Exception as error:
            status = getattr(error, "status", None)
            if status is not None:
                if status not in (429, 500, 502, 503, 504):
                    raise RuntimeError(f"Speech service rejected the request (HTTP {status})") from None
                reason = f"HTTP {status}"
            elif isinstance(error, connection_errors):
                reason = "connection/timeout"
            else:
                raise
        if attempt == 2:
            raise RuntimeError("Speech generation failed after 3 attempts: " + reason) from None
        await delay(2 ** (attempt + 1))


async def build():
    import aiohttp
    import edge_tts
    import edge_tts.communicate
    if importlib.metadata.version("edge-tts") != "7.2.8":
        raise RuntimeError("Use the documented edge-tts==7.2.8 production version")
    # Add the configured environment CA without disabling TLS validation.
    ca = os.environ.get("SSL_CERT_FILE")
    if ca:
        edge_tts.communicate._SSL_CTX.load_verify_locations(cafile=ca)
    turns = json.loads((ROOT / "build/voice/turns.json").read_text())
    casting = json.loads((ROOT / "assets/voice/mandarin-cast.json").read_text())
    output = ROOT / "build/voice/candidate"
    output.mkdir(parents=True, exist_ok=True)
    manifest, takes = {}, []
    semaphore = asyncio.Semaphore(2)
    async def produce(index, turn):
        spec = recipe(turn, casting)
        key = spec["key"]
        filename = "mandarin-" + key[:20] + ".ogg"
        target, cache = output / filename, output / (key + ".json")
        signature = sha256(json.dumps(spec, ensure_ascii=False, sort_keys=True).encode())
        metadata = json.loads(cache.read_text()) if cache.exists() else {}
        if not (target.exists() and metadata.get("recipe_sha256") == signature
                and metadata.get("asset_sha256") == sha256(target.read_bytes())):
            mp3 = output / (key + ".mp3")
            async with semaphore:
                await synthesize_with_retry(lambda: edge_tts.Communicate(
                    spec["text"], voice=spec["voice"], rate=spec["rate"],
                    proxy=os.environ.get("HTTPS_PROXY"), connect_timeout=15, receive_timeout=45,
                ).save(str(mp3)), connection_errors=(TimeoutError, aiohttp.ClientConnectionError))
            temporary = target.with_suffix(".tmp.ogg")
            subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(mp3), "-af",
                            PRODUCTION["filter"], "-ac", "1", "-ar", "24000",
                            "-c:a", "libvorbis", "-q:a", "5", str(temporary)], check=True)
            duration = float(subprocess.check_output([
                "ffprobe", "-v", "error", "-show_entries", "format=duration",
                "-of", "default=nw=1:nk=1", str(temporary)], text=True))
            if not 0.2 <= duration <= 60:
                raise ValueError("Unexpected take duration: " + key)
            temporary.replace(target)
            metadata = {**spec, "recipe_sha256": signature, "duration_seconds": duration,
                        "asset_sha256": sha256(target.read_bytes())}
            cache.write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + "\n")
        print(f"[{index+1}/{len(turns)}] {turn['speaker']} {key[:12]} ready", flush=True)
        return key, "res://assets/voice/" + filename, metadata
    for key, path, metadata in await asyncio.gather(*(produce(i, turn) for i, turn in enumerate(turns))):
        manifest[key] = path
        takes.append(metadata)
    # Publish the catalog only after every requested utterance has a verified asset.
    (output / "turn-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    provenance = {"provider": "Microsoft Edge Read Aloud via edge-tts", "locale": "zh-CN",
                  "status": "Generated Mandarin auditions; human acting/pronunciation approval pending",
                  "production": PRODUCTION, "takes": takes}
    (output / "mandarin-provenance.json").write_text(json.dumps(provenance, ensure_ascii=False, indent=2) + "\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.parse_args()
    asyncio.run(build())
