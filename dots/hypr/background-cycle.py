#!/usr/bin/env python3
import requests
import os
import subprocess
import time

# --- Configuration ---
API_KEY = "a34e8ad9a0f6d29615f699b8699b8004"
USERNAME = "Subcorporeal"
CACHE_DIR = os.path.expanduser("~/.cache/album_covers")
INTERVAL = 60  # 30 minutes in seconds
# ---------------------

os.makedirs(CACHE_DIR, exist_ok=True)

def get_recent_albums(limit=10):
    """Fetches recent tracks and extracts the 5 most recent unique albums."""
    url = f"http://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&user={USERNAME}&api_key={API_KEY}&format=json&limit={limit}"
    try:
        response = requests.get(url).json()
        tracks = response['recenttracks']['track']
        
        unique_albums = []
        seen_albums = set()
        
        for t in tracks:
            album_name = t['album']['#text']
            image_url = t['image'][-1]['#text']
            
            if album_name and album_name not in seen_albums and image_url:
                # Try to get high-res image by removing the size from URL
                high_res_url = image_url.replace("/300x300/", "/")
                unique_albums.append(high_res_url)
                seen_albums.add(album_name)
            
            if len(unique_albums) == 5:
                break
                
        return unique_albums
    except Exception as e:
        print(f"Error: {e}")
        return []

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
        album_urls = get_recent_albums()
        
        if not album_urls:
            time.sleep(60)
            continue

        for i, url in enumerate(album_urls):
            update_wallpaper(url, i)
            # Wait for 30 minutes before showing the next album in the list
            time.sleep(INTERVAL)
