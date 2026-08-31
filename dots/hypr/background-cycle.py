#!/usr/bin/env python3
import json
import os
import shutil
import subprocess
import time
import requests

# --- Configuration ---
def load_env(filepath):
    env_vars = {}
    try:
        if os.path.exists(filepath):
            with open(filepath) as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#') and '=' in line:
                        key, value = line.split('=', 1)
                        env_vars[key.strip()] = value.strip().strip('"').strip("'")
    except Exception as e:
        print(f"Error loading .env: {e}")
    return env_vars

ENV_PATH = os.path.expanduser("~/.dotfiles/.env")
ENV = load_env(ENV_PATH)

if "LASTFM_APIKEY" not in ENV or "LASTFM_USER" not in ENV:
    print(f"Error: LASTFM_APIKEY or LASTFM_USER not found in {ENV_PATH}")
    print("Please ensure your .env file contains these keys.")
    exit(1)

LASTFM_APIKEY = ENV["LASTFM_APIKEY"]
LASTFM_USER = ENV["LASTFM_USER"]

CACHE_DIR = os.path.expanduser("~/.cache/album_covers")
INTERVAL = 3600
# ---------------------

os.makedirs(CACHE_DIR, exist_ok=True)
WALLPAPER_CMD = "awww" if shutil.which("awww") else "swww" if shutil.which("swww") else None

def get_lastfm_recent_tracks(limit=10):
    """Fetches recent tracks from Last.fm with album art URLs."""
    url = f"https://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&user={LASTFM_USER}&api_key={LASTFM_APIKEY}&format=json&limit={limit}"
    try:
        response = requests.get(url, timeout=10).json()
        tracks = response['recenttracks']['track']

        unique_albums = []
        seen = set()

        for t in tracks:
            album = t['album']['#text']
            artist = t['artist']['#text']
            images = t.get('image', [])

            if album and artist and album not in seen:
                # Get the largest available image (extralarge preferred)
                img_url = None
                for img in reversed(images):
                    if img.get('#text'):
                        img_url = img['#text']
                        break

                if img_url:
                    unique_albums.append((artist, album, img_url))
                    seen.add(album)

        return unique_albums
    except Exception as e:
        print(f"Last.fm Error: {e}")
        return []

def update_wallpaper(url, index):
    path = os.path.join(CACHE_DIR, f"album_{index}.png")
    try:
        img_data = requests.get(url).content
        with open(path, 'wb') as f:
            f.write(img_data)

        if not WALLPAPER_CMD:
            print("Wallpaper tool missing: install awww (or swww on older setups).")
            return

        subprocess.run([
            WALLPAPER_CMD, "img", path,
            "--resize", "no",
            "--fill-color", "000000",
            "--transition-type", "outer",
            "--transition-pos", "top-right",
            "--transition-duration", "2"
        ])
    except Exception as e:
        print(f"Failed to set wallpaper: {e}")

if __name__ == "__main__":
    while True:
        print("\n--- Starting Cycle ---")
        albums = get_lastfm_recent_tracks(limit=10)

        if not albums:
            print("No albums found. Retrying in 60s...")
            time.sleep(60)
            continue

        for i, (artist, album, img_url) in enumerate(albums):
            print(f"Setting wallpaper {i+1}/{len(albums)}: {artist} - {album}")
            update_wallpaper(img_url, i)
            time.sleep(INTERVAL)
