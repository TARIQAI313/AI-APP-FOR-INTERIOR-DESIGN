"""Prepare public Flutter build configuration; never log API key values."""
import json
import os
from pathlib import Path
from urllib.parse import urlsplit

ROOT = Path(__file__).resolve().parents[1]
FIELDS = ("SUPABASE_URL", "SUPABASE_PUBLISHABLE_KEY")


def prepare(root=ROOT):
    target = root / "config.json"
    source = target if target.exists() else root / "config.public.json"
    try:
        config = json.loads(source.read_text(encoding="utf-8"))
    except (OSError, ValueError) as error:
        raise ValueError("Provide config.json or config.public.json with the two public Supabase fields.") from error
    if not isinstance(config, dict) or set(config) != set(FIELDS):
        raise ValueError("Configuration must contain only SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY.")
    for name in FIELDS:
        if os.environ.get(name):
            config[name] = os.environ[name].strip()
        if not isinstance(config[name], str) or not config[name].strip():
            raise ValueError(f"{name} must be a non-empty string.")
        config[name] = config[name].strip()
    url = urlsplit(config["SUPABASE_URL"])
    if (url.scheme != "https" or not url.hostname or url.username or url.password
            or url.query or url.fragment or url.path not in ("", "/")):
        raise ValueError("SUPABASE_URL must be the HTTPS project origin.")
    if not config["SUPABASE_PUBLISHABLE_KEY"].startswith("sb_publishable_"):
        raise ValueError("Use a Supabase publishable key, never a secret or service-role key.")
    config["SUPABASE_URL"] = config["SUPABASE_URL"].rstrip("/")
    target.write_text(json.dumps(config, indent=2) + "\n", encoding="utf-8")
    print("Public Flutter configuration prepared.")


if __name__ == "__main__":
    try:
        prepare()
    except ValueError as error:
        raise SystemExit(str(error)) from None
