#!/bin/bash
# Applies your monitor layout before ZarisWM starts, since its
# setupRandrMonitors() reads whatever RandR reports at connect time -- if
# you have more than one monitor, or want a specific resolution/rotation,
# that needs to happen here rather than in zaris.conf's exec-once (which
# runs after ZarisWM has already connected and read the layout once).
#
# Four monitors: DP-1 primary + DP-2 (rotated right, so its displayed
# width is 1080, not 1920 - that's why DP-3's --pos starts at 3000, not
# 3840) + DP-3 side by side, HDMI-1 mirroring DP-1 via --same-as.
xrandr \
  --output DP-1 --mode 1920x1080 --rate 165 --pos 0x0 --primary \
  --output DP-2 --mode 1920x1080 --rate 144 --rotate right --pos 1920x0 \
  --output DP-3 --mode 1920x1080 --rate 144 --pos 3000x0 \
  --output HDMI-1 --mode 1920x1080 --rate 60 --same-as DP-1

exec zaris
