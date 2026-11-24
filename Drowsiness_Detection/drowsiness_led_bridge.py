"""Drowsiness -> local YOLO BLE manager. Does not open a BLE connection."""
import socket
import time
import threading

class BleSender:
    def __init__(self, device_name=None, char_uuid=None, heartbeat_sec=2.0):
        self._level = 'UNKNOWN'
        self._lock = threading.Lock()
        self._stop = threading.Event()
        self.connected_event = threading.Event()  # local sender; not BLE connection
        self._sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self._thread = threading.Thread(target=self._loop, daemon=True)
        self._thread.start()

    def set_level(self, level):
        if level in ('SMALL', 'MEDIUM', 'BIG', 'UNKNOWN'):
            with self._lock:
                self._level = level

    def _loop(self):
        previous = None
        while not self._stop.is_set():
            with self._lock:
                level = self._level
            try:
                self._sock.sendto(level.encode('ascii'), ('127.0.0.1', 39741))
                if level != previous:
                    print(f'[DROWSINESS -> LED MANAGER] {level}', flush=True)
                    previous = level
            except OSError as exc:
                print(f'[DROWSINESS LED] {exc}', flush=True)
            self._stop.wait(0.5)

    def stop(self):
        self._stop.set()
        self._thread.join(timeout=2)
        self._sock.close()
