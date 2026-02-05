#!/usr/bin/env python3
import tidalapi
import json
import os
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
# LASTFM_SECRET is not used by this script but loaded in ENV

CACHE_FILE = os.path.expanduser("~/.config/tidal_session.json")
CACHE_DIR = os.path.expanduser("~/.cache/album_covers")
INTERVAL = 3600 
# ---------------------

os.makedirs(CACHE_DIR, exist_ok=True)

def load_session():
    """Loads the Tidal session from the local cache file."""
    if not os.path.exists(CACHE_FILE):
        print("No Tidal session file found. Please run tidal_auth.py first.")
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
        else:
            print("Session expired or invalid.")
            return None
    except Exception as e:
        print(f"Error loading session: {e}")
        return None

def get_lastfm_recent_tracks(limit=10):
    """Fetches recent tracks from Last.fm."""
    url = f"http://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&user={LASTFM_USER}&api_key={LASTFM_APIKEY}&format=json&limit={limit}"
    try:
        response = requests.get(url, timeout=10).json()
        tracks = response['recenttracks']['track']
        
        # Extract unique (Album, Artist) tuples
        unique_albums = []
        seen = set()
        
        for t in tracks:
            album = t['album']['#text']
            artist = t['artist']['#text']
            
            if album and artist and album not in seen:
                unique_albums.append((artist, album))
                seen.add(album)
                
        return unique_albums
    except Exception as e:
        print(f"Last.fm Error: {e}")
        return []

def search_tidal_artwork(session, artist, album_name):
    """Searches Tidal for an album and returns the high-res cover URL."""
    try:
        query = f"{artist} {album_name}"
        # Search for albums
        results = session.search(query, models=[tidalapi.Album], limit=1)
        
        if results['albums']:
            album = results['albums'][0]
            return album.image(1280)
    except Exception as e:
        print(f"Tidal Search Error ({artist} - {album_name}): {e}")
    return None

def get_hybrid_albums(limit=5):
    """
    1. Fetches recent history from Last.fm
    2. Searches Tidal for high-res art
    3. Returns list of high-res URLs
    """
    # 1. Get History
    recent_albums = get_lastfm_recent_tracks(limit=limit*3) # Fetch extra to handle misses
    if not recent_albums:
        return []
        
    # 2. Connect to Tidal
    session = load_session()
    if not session:
        return []
        
    # 3. Resolve Artwork
    final_urls = []
    seen_urls = set()
    
    print(f"Resolving artwork for {len(recent_albums)} albums via Tidal...")
    
    for artist, album in recent_albums:
        url = search_tidal_artwork(session, artist, album)
        
        if url and url not in seen_urls:
            final_urls.append(url)
            seen_urls.add(url)
            print(f"Found: {artist} - {album}")
        else:
            print(f"Not found/Duplicate: {artist} - {album}")
            
        if len(final_urls) >= limit:
            break
            
    return final_urls

def update_wallpaper(url, index):
    path = os.path.join(CACHE_DIR, f"album_{index}.png")
    try:
        img_data = requests.get(url).content
        with open(path, 'wb') as f:
            f.write(img_data)
        
        # swww command with a smooth transition
        subprocess.run([
            "swww", "img", path, 
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
        album_urls = get_hybrid_albums()
        
        if not album_urls:
            print("No albums found. Retrying in 60s...")
            time.sleep(60)
            continue

        for i, url in enumerate(album_urls):
            print(f"Setting wallpaper {i+1}/{len(album_urls)}")
            update_wallpaper(url, i)
            time.sleep(INTERVAL)
