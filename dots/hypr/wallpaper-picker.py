#!/usr/bin/env python3
import tidalapi
import json
import os
import sys
import argparse
import requests
import hashlib
import time
import subprocess
from concurrent.futures import ThreadPoolExecutor, as_completed

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
    except Exception:
        pass
    return env_vars

ENV_PATH = os.path.expanduser("~/.dotfiles/.env")
ENV = load_env(ENV_PATH)

LASTFM_APIKEY = ENV.get("LASTFM_APIKEY")
LASTFM_USER = ENV.get("LASTFM_USER")

CACHE_FILE = os.path.expanduser("~/.config/tidal_session.json")
CACHE_DIR = os.path.expanduser("~/.cache/album_covers")
THUMB_DIR = os.path.join(CACHE_DIR, "thumbnails")
LIST_CACHE_FILE = os.path.join(CACHE_DIR, "rofi_list_cache.txt")
os.makedirs(THUMB_DIR, exist_ok=True)

# --- Tidal Session ---
def load_session():
    if not os.path.exists(CACHE_FILE):
        return None
    try:
        with open(CACHE_FILE, 'r') as f:
            data = json.load(f)
        session = tidalapi.Session()
        session.load_oauth_session(
            data['token_type'],
            data['access_token'],
            data['refresh_token'],
            data['expiry_time']
        )
        if session.check_login():
            return session
    except:
        pass
    return None

# --- Image Caching ---
def get_cache_path(url, is_thumb=True):
    hash_name = hashlib.md5(url.encode()).hexdigest() + ".png"
    folder = THUMB_DIR if is_thumb else CACHE_DIR
    return os.path.join(folder, hash_name)

def download_image(url, is_thumb=True):
    path = get_cache_path(url, is_thumb)
    if os.path.exists(path):
        return path
    
    try:
        resp = requests.get(url, timeout=5)
        if resp.status_code == 200:
            with open(path, 'wb') as f:
                f.write(resp.content)
            return path
    except:
        return None
    return None

# --- Data Fetching ---
def get_lastfm_recent(limit=20):
    if not LASTFM_APIKEY or not LASTFM_USER:
        return []
    url = f"http://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&user={LASTFM_USER}&api_key={LASTFM_APIKEY}&format=json&limit={limit}"
    try:
        data = requests.get(url, timeout=3).json()
        tracks = data['recenttracks']['track']
        albums = []
        seen = set()
        for t in tracks:
            alb = t['album']['#text']
            art = t['artist']['#text']
            if alb and art and alb not in seen:
                albums.append((art, alb))
                seen.add(alb)
        return albums
    except:
        return []

def process_album(session, artist, album_name):
    try:
        query = f"{artist} {album_name}"
        res = session.search(query, models=[tidalapi.Album], limit=1)
        if res['albums']:
            alb = res['albums'][0]
            thumb_url = alb.image(320)
            full_url = alb.image(1280)
            icon_path = download_image(thumb_url, is_thumb=True)
            if icon_path:
                return f"{alb.artist.name} - {alb.name}\0icon\x1f{icon_path}\x1finfo\x1f{full_url}"
    except:
        pass
    return None

def process_search_result(alb):
    try:
        thumb_url = alb.image(320)
        full_url = alb.image(1280)
        icon_path = download_image(thumb_url, is_thumb=True)
        if icon_path:
            return f"{alb.artist.name} - {alb.name}\0icon\x1f{icon_path}\x1finfo\x1f{full_url}"
    except:
        pass
    return None

# --- Main Operations ---
def list_recent(force_refresh=False):
    # Check cache first
    if not force_refresh and os.path.exists(LIST_CACHE_FILE):
        # If cache is less than 30 minutes old, use it
        if time.time() - os.path.getmtime(LIST_CACHE_FILE) < 1800:
            with open(LIST_CACHE_FILE, 'r') as f:
                print(f.read(), end='')
            return

    # Generate new list
    session = load_session()
    if not session:
        print("Error: No Tidal Session\0icon\x1fsystem-error")
        return

    recents = get_lastfm_recent(20)
    lines = []
    
    with ThreadPoolExecutor(max_workers=10) as executor:
        futures = [executor.submit(process_album, session, art, alb) for art, alb in recents]
        for future in as_completed(futures):
            res = future.result()
            if res:
                lines.append(res)
    
    output = "\n".join(lines)
    print(output)
    
    # Save to cache
    with open(LIST_CACHE_FILE, 'w') as f:
        f.write(output)

def list_search(query):
    session = load_session()
    if not session:
        return
    
    try:
        res = session.search(query, models=[tidalapi.Album], limit=10)
        with ThreadPoolExecutor(max_workers=10) as executor:
            futures = [executor.submit(process_search_result, alb) for alb in res['albums']]
            for future in as_completed(futures):
                res = future.result()
                if res:
                    print(res)
    except:
        pass

def set_wallpaper(url):
    # Log attempt
    with open(os.path.join(CACHE_DIR, "wallpaper.log"), "a") as f:
        f.write(f"Downloading: {url}\n")

    path = download_image(url, is_thumb=False)
    if path:
        try:
            # Send notification
            subprocess.run(["notify-send", "Wallpaper", "Setting wallpaper..."])
            
            cmd = [
                "swww", "img", path,
                "--resize", "no",
                "--fill-color", "000000",
                "--transition-type", "outer",
                "--transition-pos", "top-right",
                "--transition-duration", "2"
            ]
            subprocess.run(cmd, check=True)
            with open(os.path.join(CACHE_DIR, "wallpaper.log"), "a") as f:
                f.write(f"Success: {path}\n")
        except Exception as e:
            subprocess.run(["notify-send", "Wallpaper Error", str(e)])
            with open(os.path.join(CACHE_DIR, "wallpaper.log"), "a") as f:
                f.write(f"Error: {e}\n")
    else:
        subprocess.run(["notify-send", "Wallpaper Error", "Failed to download image"])

# --- CLI Entry ---
if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--recent", action="store_true")
    parser.add_argument("--force", action="store_true") # Force refresh cache
    parser.add_argument("--search", type=str)
    parser.add_argument("--set", type=str)
    args = parser.parse_args()

    if args.set:
        set_wallpaper(args.set)
    elif args.search:
        list_search(args.search)
    else:
        list_recent(force_refresh=args.force)
