#!/bin/bash
# Continuous audio level stream for the bar's audio visualizer
# (AudioVisualizer.qml) - captures the default sink's monitor (what's
# currently playing, not the mic) via parec, computes RMS amplitude over
# small fixed-size chunks, and prints one 0.0-1.0-ish value per line,
# line-buffered, forever (until killed - Quickshell stops this by
# stopping the Process, not by this script exiting on its own).
#
# 8kHz mono is plenty for a level meter (not attempting frequency
# analysis, just amplitude) and keeps CPU cost low. CHUNK=320 bytes =
# 160 samples at s16le = 20ms per line, a 50Hz update rate - fast
# enough to look live, slow enough not to spam Quickshell with updates.
# (Was 800 bytes/50ms/20Hz - reported live as "the visualizer seems very
# laggy"; --latency-msec below turned out to be the bigger factor, but a
# smaller chunk shaves a further ~30ms off the worst-case per-sample
# delay on top of that.)
#
# --latency-msec=20: parec's default target latency (unset) lets
# PipeWire's own Pulse-compatibility layer pick one, which measured
# live at several hundred ms of internal buffering on this machine -
# the actual dominant source of the reported lag, not the chunking
# above (50ms was already a fast nominal rate; the real delay was
# between a sound actually starting and parec's first byte of it
# reaching this pipe at all). Explicitly forcing a low target latency
# cuts that buffering down to what a level meter actually needs -
# some extra CPU wakeups in exchange for much lower end-to-end delay,
# an easy trade for a module that isn't running at all unless a user
# opted into it (see this file's own module - AudioVisualizer.qml -
# already being off by default in modules.json for its continuous
# capture cost).
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
    --latency-msec=20 \
    --client-name=zaris-audio-visualizer --stream-name=zaris-audio-visualizer \
    | python3 -c '
import sys, struct, math

CHUNK = 320  # bytes = 160 samples at s16le = 20ms at 8kHz

while True:
    data = sys.stdin.buffer.read(CHUNK)
    if len(data) < 4:
        break
    n = len(data) // 2
    samples = struct.unpack("<%dh" % n, data[:n * 2])
    rms = math.sqrt(sum(s * s for s in samples) / n) / 32768.0
    print(f"{rms:.4f}", flush=True)
'
