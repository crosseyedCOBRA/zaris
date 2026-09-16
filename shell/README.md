# Zaris shell

This is the reference desktop shell for ZarisWM: the Quickshell-based bar,
app launcher, notification daemon config, volume OSD, and the scripts/theme
files that tie them together. The WM itself has no built-in bar (removed in
favor of this external EWMH shell — see `ROADMAP.md`), so without this,
ZarisWM is a tiling window manager with no panel, launcher, or on-screen
feedback of any kind.

This is a working *default*, not a first-run wizard — see `ROADMAP.md`'s
backlog for the planned interactive first-run setup (choosing which bar
modules show, Control Center contents, whether to enable a dock, etc.)
that will eventually customize this rather than requiring hand-edits.

This shell talks to the WM purely over X11/EWMH plus a documented set of
window rules — see [INTERFACE.md](INTERFACE.md) for the full contract,
including what's already portable to another WM and what's still
Zaris-specific. That document is prep for eventually splitting this
directory into its own repo (see `ROADMAP.md`), so other bars/shells can
be swapped in for Zaris the same way other WMs could in principle host
this one.

## What's here

| Directory              | Installs to             | What it is |
|-------------------------|--------------------------|------------|
| `quickshell/`           | `~/.config/quickshell/`  | The bar, launcher, OSD, settings window, and their shared state/config (QML + `modules.json`) |
| `zaris/`                | `~/.config/zaris/`       | `zaris.conf` (the WM config paired with this shell), `picom.conf` (recommended compositor), the session launch script, and helper scripts (power menu, screenshot, volume OSD) |
| `dunst/`                | `~/.config/dunst/`       | Notification daemon config, themed to match the shell's palette |
| `rofi/`                 | `~/.config/rofi/`        | Theme used by the power menu's `rofi -dmenu` prompt |

## Install

1. Build and install the WM itself first (see the top-level `README.md`).
2. Copy each directory above to its target location, e.g.:
   ```sh
   cp -r shell/quickshell/. ~/.config/quickshell/
   cp -r shell/zaris/.      ~/.config/zaris/
   cp -r shell/dunst/.      ~/.config/dunst/
   cp -r shell/rofi/.       ~/.config/rofi/
   chmod +x ~/.config/zaris/*.sh
   ```
3. Point your display manager's session entry (or however you start X) at
   `~/.config/zaris/start-zaris.sh`.
4. **Edit for your own hardware before first launch:**
   - If you have more than one monitor, or want a non-default
     resolution/rotation, add your own `xrandr` call to `start-zaris.sh`
     (commented-out example already in there) — it runs before ZarisWM
     connects, which is where monitor layout belongs. Left as a no-op by
     default since single-monitor setups don't need it.
   - `HwmonSensor` usages in `Bar.qml` (CPU/GPU temp) hardcode sensor labels
     (`Tctl`, `edge`) specific to this machine's CPU/GPU. Check
     `grep . /sys/class/hwmon/hwmon*/temp*_label` on your own machine and
     adjust if different — the comments in `Bar.qml` mark exactly where.
   - The bar's logo (`assets/arch-logo.svg`) is the Arch Linux logo, since
     that's what this reference machine runs — swap it for your own
     distro's icon or anything else you'd rather click to open the launcher.

## Runtime dependencies

See [../DEPENDENCIES.md](../DEPENDENCIES.md) for exact package names
(Arch/pacman verified so far). Beyond what the WM itself needs to build:

- **quickshell** (`qs`) — the shell runtime itself
- **wmctrl** — the bar's Workspaces module (`Workspaces.qml`) reads/switches workspaces entirely through this (`wmctrl -d`/`wmctrl -s`); without it, the pills just silently render as an empty row rather than erroring
- **picom** — the recommended compositor. Zaris itself does no compositing (see `ROADMAP.md`), so without this — or another compositor started some other way — windows still render correctly, but with no real alpha blending (the Bar/Control Center/Settings' translucent panels render fully opaque), no anti-aliased rounded corners, no shadows, and no background blur. `zaris.conf` already has `exec-once=picom --config ~/.config/zaris/picom.conf`; see that file for the starter config.
- **pipewire**, **pipewire-pulse**, **wireplumber** (includes `wpctl`) — audio + the volume OSD
- **dunst** — notification daemon
- **rofi** — the power menu's picker
- **maim** — screenshots (optionally **xclip** too, to also copy to clipboard)
- **xss-lock** + **i3lock** — idle-based screen lock. Both chosen specifically for being packaged natively on Arch, Debian, and Fedora alike (this project's earlier choices, `xautolock` and `betterlockscreen`/`i3lock-color`, weren't packaged on Debian at all) — see `DEPENDENCIES.md`. Plain `i3lock` has no blur/theming built in, a deliberate portability tradeoff.
- **xwallpaper** — sets the default wallpaper image (`zaris.conf`'s `exec-once=xwallpaper --zoom ~/Pictures/...`). Optionally **xsetroot** instead (usually part of `xorg-xsetroot` / `x11-apps`), if you'd rather have a plain solid color than an image
- A **Nerd Font** (JetBrainsMono Nerd Font in the reference config) — the bar's icons are glyphs from it, and it's also set as dunst's font
- **NetworkManager** (`nmcli`) — a pre-existing gap in this list, just never logged until the Network flyout pass (`NetworkPanel.qml`/`WifiNetworksService.qml`) made the dependency obvious enough to notice: every network-related bar module and the Network flyout itself (status/toggle icons, the VPN toggle, the wifi scan/connect list, the ethernet device list) go entirely through `nmcli`, with `NetworkManager.service` actually running and managing the machine's interfaces
- An icon theme (Papirus-Dark in the reference `dunstrc`) — for notification icons
- `loginctl` (systemd-logind, or **elogind** on a non-systemd system) — the power menu's suspend/reboot/shutdown actions
- **xrdb** (usually part of `x11-xserver-utils`/`xorg-x11-server-utils`) — `start-zaris.sh` sources `apply-cursor-theme.sh`, which syncs `zaris.conf`'s `cursor_theme`/`cursor_size` into the X resource database via `xrdb -merge`, alongside `~/.icons/default`/GTK's `settings.ini`, so the WM's own root cursor, GTK apps, Qt apps, and plain Xlib/XCB apps all agree on one cursor theme instead of each independently showing whatever it last picked up on its own. Guarded by `command -v xrdb` - missing it just skips that one sync step rather than failing the session

## Known machine-specific bits

Nothing here that's flagged above should stop this from running elsewhere.
Run on two machines so far: originally Artix Linux/OpenRC (3 monitors,
AMD CPU+GPU), now Arch Linux/systemd (4 monitors, one rotated) — see
`ROADMAP.md`'s "Verify on a non-OpenRC (systemd) system" entry for what
that switch actually caught (a real systemd/exec-once audio race, not
just a clean pass). See the remaining `[Beta blocker]` items in
`ROADMAP.md` for what's still unverified elsewhere.
