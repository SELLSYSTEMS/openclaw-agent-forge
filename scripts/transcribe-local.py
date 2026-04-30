#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path

from faster_whisper import WhisperModel


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Offline local audio transcription via faster-whisper.")
    p.add_argument("audio", help="Path to audio/video file")
    p.add_argument("--out", help="Write transcript to file instead of stdout")
    p.add_argument("--model", default="small", help="Whisper model size/name (default: small)")
    p.add_argument("--language", default="auto", help="Language code, or 'auto' (default)")
    p.add_argument("--device", default="cpu", help="Inference device (default: cpu)")
    p.add_argument("--compute-type", default="int8", help="Compute type (default: int8)")
    p.add_argument("--beam-size", type=int, default=5, help="Beam size (default: 5)")
    p.add_argument("--timestamps", action="store_true", help="Include timestamps per segment")
    p.add_argument("--no-vad", action="store_true", help="Disable VAD filter")
    return p


def main() -> int:
    args = build_parser().parse_args()
    path = Path(args.audio).expanduser().resolve()
    if not path.exists():
        raise SystemExit(f"Audio file not found: {path}")

    model = WhisperModel(args.model, device=args.device, compute_type=args.compute_type)
    language = None if args.language == "auto" else args.language
    segments, info = model.transcribe(
        str(path),
        language=language,
        beam_size=args.beam_size,
        vad_filter=not args.no_vad,
    )

    if args.timestamps:
        text = "\n".join(
            f"[{seg.start:.2f}-{seg.end:.2f}] {seg.text.strip()}"
            for seg in segments
            if seg.text.strip()
        )
    else:
        text = " ".join(seg.text.strip() for seg in segments if seg.text.strip()).strip()

    header = f"# language={info.language} prob={info.language_probability:.3f}\n"
    payload = header + text + ("\n" if text and not text.endswith("\n") else "")

    if args.out:
        out = Path(args.out).expanduser()
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(payload, encoding="utf-8")
    else:
        print(payload, end="")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
