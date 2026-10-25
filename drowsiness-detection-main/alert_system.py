"""
نظام الإنذار الصوتي المحسّن
==============================
ضع هذا الكود في demo.py بدل _play_alert() الحالية.

ثلاث طبقات للإنذار:
  1. صوت تحذير خفيف (WARNING)  — بيب واحد
  2. صوت خطر متكرر (DANGER)    — بيب قوي يتكرر كل ثانيتين
  3. توليد صوت تلقائي إذا ما في alert.wav
"""

import math
import struct
import threading
import time
import wave
from pathlib import Path

import pygame

PROJECT_ROOT = Path(__file__).resolve().parent.parent


# ──────────────────────────────────────────────
# توليد صوت بيب برمجياً (بدون ملف خارجي)
# ──────────────────────────────────────────────

def _generate_beep_wav(path: Path, freq: float, duration: float,
                        volume: float = 0.9, sample_rate: int = 44100) -> None:
    """يولّد ملف WAV بنغمة نقية — يُستخدم إذا ما وجد alert.wav."""
    n_samples = int(sample_rate * duration)
    with wave.open(str(path), "w") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)          # 16-bit
        wf.setframerate(sample_rate)
        for i in range(n_samples):
            # fade in/out لأول وآخر 10% من الصوت لتجنب الطقطقة
            t      = i / sample_rate
            fade   = min(i, n_samples - i, int(n_samples * 0.1))
            amp    = volume * (fade / (n_samples * 0.1)) if fade < n_samples * 0.1 else volume
            sample = int(amp * 32767 * math.sin(2 * math.pi * freq * t))
            wf.writeframes(struct.pack("<h", sample))


def _ensure_alert_sounds(root: Path) -> dict:
    """
    يتأكد إن ملفات الصوت موجودة.
    إذا ما وجد → يولّدها تلقائياً.
    يرجع dict بمسارات الملفات.
    """
    sounds = {
        "warning": root / "alert_warning.wav",   # تحذير — بيب واحد 880 Hz
        "danger":  root / "alert_danger.wav",    # خطر   — بيب قوي 1200 Hz
    }
    if not sounds["warning"].exists():
        print("  [Alert] توليد صوت التحذير تلقائياً ...")
        _generate_beep_wav(sounds["warning"], freq=880,  duration=0.4)
    if not sounds["danger"].exists():
        print("  [Alert] توليد صوت الخطر تلقائياً ...")
        _generate_beep_wav(sounds["danger"],  freq=1200, duration=0.8, volume=1.0)

    # إذا وجد alert.wav القديم، استخدمه كصوت الخطر
    legacy = root / "alert.wav"
    if legacy.exists():
        sounds["danger"] = legacy

    return sounds


# ──────────────────────────────────────────────
# مدير الإنذار الصوتي
# ──────────────────────────────────────────────

class AlertManager:
    """
    يدير الإنذار الصوتي في thread منفصل
    حتى ما يوقف معالجة الفيديو.

    الاستخدام:
        alert = AlertManager(PROJECT_ROOT)
        alert.update("danger")    # شغّل خطر
        alert.update("warning")   # شغّل تحذير
        alert.update("none")      # وقّف الصوت
    """

    REPEAT_INTERVAL = 2.0   # ثواني بين كل تكرار في وضع DANGER

    def __init__(self, root: Path):
        pygame.mixer.pre_init(frequency=44100, size=-16, channels=1, buffer=512)
        if not pygame.mixer.get_init():
            pygame.mixer.init()

        self._sounds  = _ensure_alert_sounds(root)
        self._state   = "none"          # "none" | "warning" | "danger"
        self._lock    = threading.Lock()
        self._thread  = threading.Thread(target=self._loop, daemon=True)
        self._thread.start()

    def update(self, state: str) -> None:
        """يستدعى كل فريم بالحالة الحالية."""
        with self._lock:
            self._state = state

    def _play(self, key: str) -> None:
        try:
            if not pygame.mixer.music.get_busy():
                pygame.mixer.music.load(str(self._sounds[key]))
                pygame.mixer.music.play()
        except Exception as e:
            print(f"  [Alert] خطأ في تشغيل الصوت: {e}")

    def _loop(self) -> None:
        """
        Thread يشتغل بشكل مستمر:
        - warning: بيب واحد عند بداية التحذير فقط
        - danger:  بيب يتكرر كل REPEAT_INTERVAL ثانية
        """
        last_state      = "none"
        last_play_time  = 0.0

        while True:
            with self._lock:
                state = self._state

            now = time.time()

            if state == "danger":
                # شغّل فوراً عند أول كشف، ثم كل ثانيتين
                if (last_state != "danger" or
                        now - last_play_time >= self.REPEAT_INTERVAL):
                    self._play("danger")
                    last_play_time = now

            elif state == "warning":
                # صوت واحد فقط عند بداية التحذير
                if last_state != "warning":
                    self._play("warning")
                    last_play_time = now

            else:
                # لا إنذار: أوقف الصوت إذا كان شاغلاً
                if pygame.mixer.music.get_busy():
                    pygame.mixer.music.stop()

            last_state = state
            time.sleep(0.05)    # فحص كل 50ms


# ──────────────────────────────────────────────
# كيف تدمج هذا في demo.py
# ──────────────────────────────────────────────
#
# 1. في أعلى demo.py، احذف _play_alert() واستبدلها بـ:
#
#       from alert_system import AlertManager
#
# 2. في run_demo()، أضف بعد تحميل النماذج:
#
#       alert_mgr = AlertManager(PROJECT_ROOT)
#
# 3. في حلقة while، احذف:
#
#       if is_drowsy and not was_alert:
#           _play_alert()
#
#    واستبدلها بـ:
#
#       if is_drowsy:
#           alert_mgr.update("danger")
#       elif is_warning:
#           alert_mgr.update("warning")
#       else:
#           alert_mgr.update("none")
#
# ──────────────────────────────────────────────


# اختبار مستقل
if __name__ == "__main__":
    print("اختبار نظام الإنذار ...")
    mgr = AlertManager(PROJECT_ROOT)

    print("تحذير (warning) لمدة 3 ثواني ...")
    mgr.update("warning")
    time.sleep(3)

    print("خطر (danger) لمدة 6 ثواني — يتكرر كل 2 ثانية ...")
    mgr.update("danger")
    time.sleep(6)

    print("إيقاف ...")
    mgr.update("none")
    time.sleep(1)
    print("تم.")
