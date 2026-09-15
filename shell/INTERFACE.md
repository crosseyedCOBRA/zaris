# Shell/WM interface contract

This shell (`shell/quickshell/`) is a separate process from ZarisWM — it
talks to whatever window manager is running purely over X11/EWMH plus a
couple of WM-specific config lines, not through any private API. This
document is the decoupling pass mentioned in `ROADMAP.md`: pulling that
contract out of scattered comments in `zaris.conf` and the QML files into
one place, ahead of the shell eventually moving to its own repo so other
WMs/bars can be mixed and matched with Zaris.

Everything below is either already true today (works against any
EWMH-compliant WM) or is called out explicitly as Zaris-specific.

## Portable today (any EWMH-compliant X11 WM)

- Workspace switching/naming, the taskbar/active-window tracking, and the
  bar's tray all read standard EWMH properties (`_NET_CURRENT_DESKTOP`,
  `_NET_NUMBER_OF_DESKTOPS`, `_NET_DESKTOP_NAMES`, `_NET_CLIENT_LIST`,
  `_NET_ACTIVE_WINDOW`, `_NET_WM_STRUT_PARTIAL` for the bar's own
  space reservation) — no Zaris-specific atoms involved.
- `ControlCenter.qml`, `Settings.qml`, the calendar flyout, the
  notification history panel, and the taskbar-mode launcher are all
  Quickshell `PopupWindow`s anchored directly to another one of the
  shell's own surfaces (the bar) via Quickshell's own anchoring API —
  they position themselves and need no WM-side window rule at all.
- The shell's own IPC surface (`qs ipc call <target> <action>`, backed by
  `IpcHandler { target: "..." }` in the relevant QML file) is how
  `zaris.conf`'s keybinds and `osd-volume.sh` talk to the shell — this is
  Quickshell's mechanism, not a WM-provided one, so it works identically
  regardless of which WM is invoking it. Current targets: `launcher`,
  `osd`, `brightness`, `clipboard`, `wallpaper`, `avatar`.

## Zaris-specific requirements

A different WM wanting to host this shell as-is needs to replicate these;
these are also exactly what would need re-expressing in whatever config
format a different WM uses.

**1. Float + position every other popup by window title.** Everything
that *isn't* one of the anchored PopupWindows above is a real top-level X
window Quickshell creates with a specific `_NET_WM_NAME`/title and no
`WM_CLASS` (confirmed via `xprop` — Quickshell's `FloatingWindow` never
sets one), so matching has to be by title. The exact set, from
`shell/zaris/zaris.conf`'s own inline comments:

| Title | WM treatment needed |
|---|---|
| `Launcher` | float, center |
| `OSD` | float, center |
| `Dock-top` / `Dock-bottom` / `Dock-left` / `Dock-right` | float, anchored to that screen edge (only relevant in Dock's "floating" mode — "reserved" mode is a `PanelWindow` needing no rule) |
| `Pin to Dock` | float, bottom-center |
| `Bluetooth` | float, center |
| `Clipboard History` | float, center |
| `Wallpaper Picker` | float, center |
| `Choose Profile Picture` | float, center |
| `Choose Icon` | float, center |
| `Power Menu` | float, center |
| `Choose Folder` | float, center |

In Zaris's own config syntax this is `windowrule=float,title:^Launcher$` /
`windowrule=center,title:^Launcher$` etc. — see `shell/zaris/zaris.conf`
for the full, currently-shipped set with per-window rationale.

**2. Keep all of the above always-on-top of tiled content.** Zaris tracks
every one of these (plus the anchored PopupWindows) in one
`alwaysOnTopWindows` set (`windowManager.hpp`/`reassertAlwaysOnTop()`),
reasserted every event-loop tick, and deliberately does *not* try to
single out e.g. just Settings — X11 gives no reliable way to distinguish
"Quickshell's Settings popup" from "Quickshell's calendar flyout" from
outside Quickshell itself, so any WM hosting this shell needs an
equivalent "float every window this shell creates above the tiling layer"
mechanism, not just a one-off special case.

**3. `windowrule=fullscreen,class:^steam_app_.*$`.** Not shell-specific,
but shipped alongside it in the reference config — Steam sets this
`WM_CLASS` for any game it launches.

## Known deep coupling (not yet decoupled)

`ThemeConfig.qml`'s color-preset save path directly rewrites
`col.active_border=0x...`/`col.inactive_border=0x...` lines inside
`~/.config/zaris/zaris.conf` itself — regex find-and-replace against
Zaris's own config file syntax, not an API call. This is the one place
the shell reaches into a specific WM's config format rather than talking
to it over EWMH or IPC. A real multi-WM split would need this replaced
with something the WM exposes deliberately (an IPC call, a separate
small state file the WM watches, etc.) rather than text-mutating another
project's config file — tracked as follow-up work for whenever the actual
repo split happens, not solved by this pass.

## Environment/branding assumptions

- `$HOME/.local/bin/zaris` is what `shell/zaris/start-zaris.sh` execs —
  fine for Zaris itself, but obviously specific to it; a different WM
  needs its own launch script, not this one.
- The bar's launcher-button logo (`assets/artix.svg`) and the hardcoded
  hwmon sensor labels in `Bar.qml` are reference-machine artifacts, not
  interface requirements — both already called out as swap-before-first-
  launch items in `shell/README.md`.
