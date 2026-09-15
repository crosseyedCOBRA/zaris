#!/bin/bash
# Continuous audio level stream for the bar's audio visualizer
# (AudioVisualizer.qml) - captures the default sink's monitor (what's
# currently playing, not the mic) via parec, computes RMS amplitude over
# small fixed-size chunks, and prints one 0.0-1.0-ish value per line,
# line-buffered, forever (until killed - Quickshell stops this by
# stopping the Process, not by this script exiting on its own).
#
# 8kHz mono is plenty for a level meter (not attempting frequency
# analysis, just amplitude) and keeps CPU cost low. CHUNK=800 bytes =
# 400 samples at s16le = 50ms per line, a ~20Hz update rate - fast
# enough to look live, slow enough not to spam Quickshell with updates.
#
# --client-name/--stream-name: PipeWire has no separate "media class" for
# a monitor-loopback capture vs a real microphone capture - both show up
# as plain Stream/Input/Audio, confirmed live (this exact stream tripped
# PrivacyIndicator.qml's mic detection as a false positive before this
# was added). Named explicitly so that module can filter this specific
# stream back out by name rather than genuinely flagging "recording" for
# something that's just visualizing playback.
set -eu

exec parec --raw --format=s16le --rate=8000 --channels=1 -d @DEFAULT_MONITOR@ \
    --client-name=zaris-audio-visualizer --stream-name=zaris-audio-visualizer \
    | python3 -c '
import sys, struct, math

CHUNK = 800  # bytes = 400 samples at s16le = 50ms at 8kHz

while True:
    data = sys.stdin.buffer.read(CHUNK)
    if len(data) < 4:
        break
    n = len(data) // 2
    samples = struct.unpack("<%dh" % n, data[:n * 2])
    rms = math.sqrt(sum(s * s for s in samples) / n) / 32768.0
    print(f"{rms:.4f}", flush=True)
'
