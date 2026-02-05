#!/usr/bin/env python3
"""
Rofi Tidal Interface - Isolated Player & Album View
"""

import tidalapi
import json
import os
import sys
import subprocess
import socket
import time

CACHE_FILE = os.path.expanduser("~/.config/tidal_session.json")
IPC_SOCKET = "/tmp/rofi_tidal_mpv.sock"
CONTEXT_FILE = "/tmp/rofi_tidal_context.json"

def load_session():
    if not os.path.exists(CACHE_FILE): return None
    try:
        with open(CACHE_FILE, 'r') as f: data = json.load(f)
        session = tidalapi.Session()
        session.load_oauth_session(data['token_type'], data['access_token'], data['refresh_token'], data['expiry_time'])
        if session.check_login(): return session
    except: pass
    return None

def send_mpv_command(command):
    if not os.path.exists(IPC_SOCKET): return None
    try:
        client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        client.connect(IPC_SOCKET)
        client.send(json.dumps({"command": command}).encode('utf-8') + b'\n')
        response = client.recv(4096)
        client.close()
        return json.loads(response.decode('utf-8'))
    except: return None

def get_property(prop):
    res = send_mpv_command(["get_property", prop])
    return res.get('data') if res and res.get('error') == 'success' else None

def get_now_playing():
    if not os.path.exists(IPC_SOCKET): return None, "stopped"
    try:
        subprocess.check_call(["pgrep", "-f", f"input-ipc-server={IPC_SOCKET}"], stdout=subprocess.DEVNULL)
        title = get_property("media-title")
        pause = get_property("pause")
        status = "paused" if pause else "playing"
        return title or "Loading...", status
    except: return None, "stopped"

def save_context(album_id, album_name):
    try:
        with open(CONTEXT_FILE, 'w') as f:
            json.dump({'id': album_id, 'name': album_name}, f)
    except: pass

def get_context():
    try:
        if os.path.exists(CONTEXT_FILE):
            with open(CONTEXT_FILE, 'r') as f:
                return json.load(f)
    except: pass
    return None

def toggle_playback(): send_mpv_command(["cycle", "pause"])
def stop_playback(): send_mpv_command(["quit"])

def play_url(url, title):
    stop_playback()
    time.sleep(0.1)
    subprocess.Popen([
        'mpv', '--no-video', '--force-window=no', '--no-terminal',
        f'--input-ipc-server={IPC_SOCKET}',
        f'--title=Tidal: {title}',
        str(url)
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    subprocess.Popen(['notify-send', '-i', 'audio-x-generic', 'Tidal', f'Playing: {title}'])

def play_track(track_id, name, artist):
    session = load_session()
    if not session: return
    try:
        t = session.track(track_id)
        
        # Save album context
        if t.album:
            save_context(t.album.id, t.album.name)
            
        url = t.get_url()
        if url: play_url(url, f"{name} - {artist}")
    except Exception as e: print(f"! Error: {e}")

def list_album_tracks(album_id, album_name):
    session = load_session()
    if not session: return
    
    print(f"\0prompt\x1fAlbum: {album_name}")
    print("\0message\x1fSelect track to play")
    print("Back")
    
    try:
        album = session.album(album_id)
        for t in album.tracks():
            artist = t.artist.name if t.artist else "Unknown"
            # Highlight currently playing if match found (simple heuristic)
            now, _ = get_now_playing()
            prefix = "▶ " if now and t.name in now else f"{t.track_num}. "
            
            info = json.dumps({'t': t.id, 'n': t.name, 'a': artist})
            dur = f"{t.duration//60}:{t.duration%60:02d}" if hasattr(t, 'duration') else ""
            print(f"{prefix}{t.name} [{dur}]\0icon\x1faudio-x-generic\x1finfo\x1f{info}")
    except: print("! Failed to load album")

def search(query):
    session = load_session()
    if not session: return print("! Login Required")
    
    print(f"\0prompt\x1fSearch: {query}")
    print("\0message\x1fSelect to play (Tracks) or view (Albums)")
    print("Back")
    
    try:
        # Tracks
        for t in session.search(query, models=[tidalapi.Track], limit=8)['tracks']:
            artist = t.artist.name if t.artist else "Unknown"
            info = json.dumps({'t': t.id, 'n': t.name, 'a': artist})
            print(f"🎵 {t.name} - {artist}\0icon\x1faudio-x-generic\x1finfo\x1f{info}")
        
        # Albums
        for a in session.search(query, models=[tidalapi.Album], limit=8)['albums']:
            artist = a.artist.name if a.artist else "Unknown"
            info = json.dumps({'view_al': a.id, 'n': a.name})
            print(f"💿 {a.name} - {artist}\0icon\x1fmedia-optical\x1finfo\x1f{info}")
    except: print("! Search Failed")

def show_main_menu():
    now, status = get_now_playing()
    print("\0prompt\x1fTidal")
    
    if now:
        # Playback controls
        icon = "⏸" if status == "playing" else "▶"
        print(f"\0message\x1f{icon} {now}")
        
        # Context (Current Album)
        ctx = get_context()
        if ctx:
            info = json.dumps({'view_al': ctx['id'], 'n': ctx['name']})
            print(f"💿 View Album: {ctx['name']}\0icon\x1fmedia-optical\x1finfo\x1f{info}")
            
        print(f"⏸ Pause\0icon\x1fmedia-playback-pause" if status == "playing" else f"▶ Play\0icon\x1fmedia-playback-start")
        print("⏹ Stop\0icon\x1fmedia-playback-stop")
    else:
        print("\0message\x1fType to search...")
    print("")

def main():
    selection = sys.argv[1] if len(sys.argv) > 1 else ""
    info = os.environ.get('ROFI_INFO', '')
    
    if info:
        try:
            d = json.loads(info)
            if 't' in d:
                play_track(d['t'], d['n'], d['a'])
                # After selecting a track, show the album view immediately
                # so user can see other songs
                session = load_session()
                t = session.track(d['t'])
                if t.album: list_album_tracks(t.album.id, t.album.name)
                return
            elif 'view_al' in d:
                list_album_tracks(d['view_al'], d['n'])
                return
        except: pass
        show_main_menu()
        return

    if selection == "Back": show_main_menu()
    elif "Pause" in selection or "Play" in selection:
        toggle_playback(); show_main_menu()
    elif "Stop" in selection:
        stop_playback(); show_main_menu()
    elif selection.strip():
        search(selection)
    else:
        show_main_menu()

if __name__ == "__main__":
    main()
