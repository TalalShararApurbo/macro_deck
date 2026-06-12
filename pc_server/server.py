import socket
import ctypes
import threading
import sys
import os
import time

# Try importing keyboard for macro simulation and recording
try:
    import keyboard
except ImportError:
    keyboard = None

# Try importing GUI/Tray libraries
try:
    import pystray
    from PIL import Image, ImageDraw
except ImportError:
    pystray = None
    Image = None

# Win32 Virtual Key Codes for system volume (zero dependencies on Windows)
VK_VOLUME_MUTE = 0xAD
VK_VOLUME_DOWN = 0xAE
VK_VOLUME_UP = 0xAF

# Default port
PORT = 8080

def press_system_key(vk_code):
    """Simulates a system keypress using Win32 API with proper scan codes and extended flags."""
    try:
        # Explicit scan code overrides for multimedia keys (MapVirtualKey can return 0 for these)
        scan_codes = {
            0xAD: 0x20, # VK_VOLUME_MUTE
            0xAE: 0x2E, # VK_VOLUME_DOWN
            0xAF: 0x30, # VK_VOLUME_UP
        }
        scan_code = scan_codes.get(vk_code, 0)
        if scan_code == 0:
            scan_code = ctypes.windll.user32.MapVirtualKeyW(vk_code, 0)

        # Media and volume keys are extended keys (0x0001)
        flags_down = 0x0001
        flags_up = 0x0001 | 0x0002
        ctypes.windll.user32.keybd_event(vk_code, scan_code, flags_down, 0)
        ctypes.windll.user32.keybd_event(vk_code, scan_code, flags_up, 0)
    except Exception as e:
        print(f"[Error] Failed to trigger system key: {e}")

# Default actions mapped to keyboard shortcuts. Customize these for OBS, etc.
ACTION_MAPPINGS = {
    "STREAM": lambda: keyboard.send("ctrl+alt+shift+s") if keyboard else print("[Info] STREAM triggered (requires keyboard package)"),
    "RECORD": lambda: keyboard.send("ctrl+alt+shift+r") if keyboard else print("[Info] RECORD triggered (requires keyboard package)"),
    "CLIPS": lambda: keyboard.send("ctrl+alt+shift+c") if keyboard else print("[Info] CLIPS triggered (requires keyboard package)"),
    "MIC_MUTE": lambda: keyboard.send("ctrl+alt+shift+m") if keyboard else print("[Info] MIC_MUTE triggered (requires keyboard package)"),
    "DEAFEN": lambda: keyboard.send("ctrl+alt+shift+d") if keyboard else print("[Info] DEAFEN triggered (requires keyboard package)"),
    "CAMERA": lambda: keyboard.send("ctrl+alt+shift+v") if keyboard else print("[Info] CAMERA triggered (requires keyboard package)"),
    "SCENE_1": lambda: keyboard.send("ctrl+alt+1") if keyboard else print("[Info] SCENE_1 triggered (requires keyboard package)"),
    "SCENE_2": lambda: keyboard.send("ctrl+alt+2") if keyboard else print("[Info] SCENE_2 triggered (requires keyboard package)"),
}

# Global Server variables
sock = None
server_thread = None
server_running = False
tray_icon = None

# Macro Recording State
is_recording = False
recording_client_addr = None
pressed_keys = set()
recorded_sequence = []
keyboard_hook = None

def get_primary_ip():
    """Gets the primary active local IP address connected to the router/internet."""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # Doesn't send any data, just queries the routing table
        s.connect(('8.8.8.8', 80))
        ip = s.getsockname()[0]
        if ip != '127.0.0.1':
            return ip
    except Exception:
        pass
    finally:
        s.close()
        
    # Fallback if offline
    try:
        hostname = socket.gethostname()
        info = socket.getaddrinfo(hostname, None)
        for item in info:
            ip = item[4][0]
            if ":" not in ip and ip != "127.0.0.1":
                return ip
    except:
        pass
        
    return '127.0.0.1'

def show_native_message_box():
    """Renders a native Windows dialog box displaying connection details."""
    ip = get_primary_ip()
    message = f"Configure your mobile app with:\n\nIP Address: {ip}\nPort: {PORT}"
    
    # Run in a thread to prevent blocking PyStray tray execution
    threading.Thread(
        target=lambda: ctypes.windll.user32.MessageBoxW(0, message, "Macro-Deck Connection Info", 0x40 | 0x0),
        daemon=True
    ).start()

def handle_key_event(event):
    """Global keyboard hook callback to capture key combinations."""
    global is_recording, recording_client_addr, pressed_keys, recorded_sequence, sock
    if not is_recording or sock is None or recording_client_addr is None:
        return

    key = event.name
    if not key:
        return

    if event.event_type == 'down':
        if key not in pressed_keys:
            pressed_keys.add(key)
            recorded_sequence.append(key)
    elif event.event_type == 'up':
        if key in pressed_keys:
            pressed_keys.remove(key)
        
        # When all keys are released, finish recording and send response
        if len(pressed_keys) == 0 and len(recorded_sequence) > 0:
            combo = "+".join(recorded_sequence)
            print(f"[Record] Captured combination: {combo}")
            
            try:
                response = f"RECORD_RESULT:{combo}"
                sock.sendto(response.encode('utf-8'), recording_client_addr)
            except Exception as e:
                print(f"[Error] Failed to send record result: {e}")
            
            # Reset recording states
            is_recording = False
            recorded_sequence = []

def execute_command(command, client_addr):
    """Route commands received from the mobile application."""
    global is_recording, recording_client_addr, pressed_keys, recorded_sequence, keyboard_hook, sock
    
    print(f"[UDP] Command: '{command}' from {client_addr}")

    if command == "VOLUME_UP":
        press_system_key(VK_VOLUME_UP)
    elif command == "VOLUME_DOWN":
        press_system_key(VK_VOLUME_DOWN)
    elif command == "MUTE":
        press_system_key(VK_VOLUME_MUTE)

    elif command == "RECORD_START":
        if keyboard is None:
            print("[Warning] Cannot start recording: 'keyboard' library not installed.")
            if sock:
                sock.sendto(b"RECORD_RESULT:Error: Run 'pip install keyboard' on PC", client_addr)
            return

        print(f"[Record] Started keybind recording for client {client_addr}")
        is_recording = True
        recording_client_addr = client_addr
        pressed_keys.clear()
        recorded_sequence = []
        
        if keyboard_hook is None:
            keyboard_hook = keyboard.hook(handle_key_event)

    elif command == "RECORD_STOP":
        print("[Record] Recording stopped by mobile client")
        is_recording = False

    elif command.startswith("RUN_MACRO:"):
        macro_combo = command[len("RUN_MACRO:"):]
        if keyboard is None:
            print(f"[Warning] Cannot run macro '{macro_combo}': 'keyboard' library not installed.")
            return
        print(f"[Macro] Simulating keystroke: {macro_combo}")
        try:
            keyboard.send(macro_combo)
        except Exception as e:
            print(f"[Error] Keystroke simulation failed: {e}")

    else:
        # Default action mappings
        if command in ACTION_MAPPINGS:
            ACTION_MAPPINGS[command]()
        else:
            print(f"[Info] Unhandled command: {command}")

def start_udp_server():
    """Binds UDP socket and processes packets."""
    global sock, server_running
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    
    try:
        sock.bind(('', PORT))
        server_running = True
        print(f"[Server] UDP listener bound to port {PORT}")
    except Exception as e:
        print(f"[Server] Failed to bind to port {PORT}: {e}")
        server_running = False
        return

    while server_running:
        try:
            data, addr = sock.recvfrom(1024)
            if not data:
                continue
            command = data.decode('utf-8').strip()
            execute_command(command, addr)
        except Exception as e:
            # Socket closed or interrupted
            break
            
    print("[Server] UDP listener thread stopped")

def run_server_threaded():
    """Launches the server socket thread."""
    global server_thread
    server_thread = threading.Thread(target=start_udp_server, daemon=True)
    server_thread.start()

def stop_server():
    """Signals socket thread shutdown and closes socket."""
    global server_running, sock, keyboard_hook
    server_running = False
    if keyboard_hook is not None and keyboard is not None:
        try:
            keyboard.unhook(keyboard_hook)
        except:
            pass
        keyboard_hook = None
    if sock:
        sock.close()
        sock = None

# Tray Icon management functions
def create_tray_image():
    """Generates a dynamic 64x64 icon image for the system tray."""
    if Image is None or ImageDraw is None:
        return None
    width = 64
    height = 64
    # Create dark gray canvas
    image = Image.new('RGB', (width, height), color=(18, 18, 18))
    dc = ImageDraw.Draw(image)
    # Draw cyan box outline
    dc.rectangle([4, 4, width-4, height-4], outline=(0, 255, 255), width=3)
    # Draw cyan "M" lines
    dc.line([(18, 18), (18, 46)], fill=(0, 255, 255), width=4) # Left leg
    dc.line([(46, 18), (46, 46)], fill=(0, 255, 255), width=4) # Right leg
    dc.line([(18, 18), (32, 32)], fill=(0, 255, 255), width=4) # Left diagonal
    dc.line([(46, 18), (32, 32)], fill=(0, 255, 255), width=4) # Right diagonal
    return image

def on_show_info_clicked(icon, item):
    """Handles tray icon click for displaying IP details."""
    show_native_message_box()

def on_restart_clicked(icon, item):
    """Handles tray icon restart command."""
    print("[Tray] Restarting UDP Server...")
    stop_server()
    time.sleep(0.5)
    run_server_threaded()
    icon.notify("UDP Server restarted successfully!", "Macro-Deck")

def on_exit_clicked(icon, item):
    """Handles tray icon quit command."""
    print("[Tray] Shutting down application...")
    stop_server()
    icon.stop()
    sys.exit(0)

def main():
    global tray_icon

    # Display instructions and local IP in console (if console is visible)
    primary_ip = get_primary_ip()

    print("================================================================")
    print("                  MACRO-DECK PC UDP SERVER                      ")
    print("================================================================")
    if keyboard is None:
        print("WARNING: The 'keyboard' Python package is not installed.")
        print("To enable custom hotkeys and macro recording, please run:")
        print("   pip install keyboard")
        print("----------------------------------------------------------------")
    
    if pystray is None:
        print("INFO: 'pystray' and/or 'pillow' packages are not installed.")
        print("Running in CLI-only mode. To enable the system tray icon, run:")
        print("   pip install pystray pillow")
        print("----------------------------------------------------------------")

    print(f"Listening on UDP port {PORT}...")
    print("Configure this IP address in your Mobile App settings:")
    print(f"  -> {primary_ip}")
    print("================================================================")

    # Start the server socket in a thread
    run_server_threaded()

    # Launch PyStray tray icon if libraries are available, otherwise run in console loop
    if pystray is not None and create_tray_image() is not None:
        print("[Tray] Launching system tray icon...")
        menu = pystray.Menu(
            pystray.MenuItem('Show Connection Info', on_show_info_clicked),
            pystray.MenuItem('Restart Server', on_restart_clicked),
            pystray.MenuItem('Exit', on_exit_clicked)
        )
        tray_icon = pystray.Icon("MacroDeck", create_tray_image(), "Macro-Deck Server", menu)
        
        # Setup callback to show toast notification on start
        def on_setup(icon):
            icon.visible = True
            ip = get_primary_ip()
            icon.notify(
                f"IP: {ip}\nPort: {PORT}\nRight-click tray icon to show info!",
                "Macro-Deck Server Active"
            )

        tray_icon.run(setup=on_setup)
    else:
        print("[Console] Running in CLI mode. Press Ctrl+C to terminate.")
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            print("\n[Console] Shutting down server...")
            stop_server()

if __name__ == '__main__':
    main()
