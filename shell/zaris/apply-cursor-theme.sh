#!/bin/bash
# Syncs one cursor theme/size (read from zaris.conf's own cursor_theme=/
# cursor_size= lines - see that file's own comment) out to every place an
# X11 app might independently look for its cursor, so they all agree
# instead of each toolkit showing whatever it last picked up on its own -
# confirmed live as a real, visible mismatch on this project's own
# reference machine before this existed: Xresources said one Bibata
# variant (stale, left over from some earlier one-off `xrdb` load),
# ~/.icons/default and GTK's settings.ini both said a different one, and
# Qt apps had no cursor setting anywhere, each of the three toolkit
# families effectively picking its own answer.
#
# Meant to be *sourced*, not executed as its own subprocess -
# `source apply-cursor-theme.sh` from start-zaris.sh, before `exec zaris`
# - specifically so the `export XCURSOR_THEME`/`XCURSOR_SIZE` below lands
# in start-zaris.sh's own shell and is therefore inherited by `exec zaris`
# and everything Zaris itself launches afterward (every zaris.conf
# exec-once line, Quickshell, etc.). A plain subprocess/child script
# would only affect its own environment, gone the moment it exits -
# useless for this, since the whole point is the *session's* environment,
# not a one-off command's.
#
# Order matters: this must run before `exec zaris`, not as one of
# zaris.conf's own exec-once lines - Zaris' own updateRootCursor()
# (windowManager.cpp) creates its root cursor once, at startup, by asking
# xcb-util-cursor to resolve "left_ptr" against whatever XCURSOR_THEME/
# Xcursor.theme already exists *at that moment* (the same standard
# env-var-then-X-resource resolution order every Xcursor-aware toolkit
# uses) - an exec-once line runs after that has already happened, too
# late to change the WM's own cursor, even though it'd still correctly
# reach every app launched afterward.

_ZARIS_CONF="$HOME/.config/zaris/zaris.conf"

_cursor_theme=$(grep -m1 '^cursor_theme=' "$_ZARIS_CONF" 2>/dev/null | cut -d= -f2 | cut -d' ' -f1)
_cursor_size=$(grep -m1 '^cursor_size=' "$_ZARIS_CONF" 2>/dev/null | cut -d= -f2 | cut -d' ' -f1)

# Sensible fallbacks if zaris.conf has no cursor_theme/cursor_size lines
# at all (an older config from before these existed) - "Adwaita" ships in
# the base `hicolor`/xcursor-themes set on effectively every distro, a
# safe default that isn't specific to any one theme pack a fresh install
# might not have.
_cursor_theme="${_cursor_theme:-Adwaita}"
_cursor_size="${_cursor_size:-24}"

export XCURSOR_THEME="$_cursor_theme"
export XCURSOR_SIZE="$_cursor_size"

# ~/.icons/default/index.theme - the legacy/fallback theme location a
# number of apps (and some display managers' own greeter) check before
# anything env-var or Xresource based.
mkdir -p "$HOME/.icons/default"
cat > "$HOME/.icons/default/index.theme" <<EOF
[Icon Theme]
Inherits=$_cursor_theme
EOF

# X resource database - what Zaris' own updateRootCursor() (via
# xcb-util-cursor) and any plain Xlib/XCB app ultimately resolve against.
# Merged directly into the live database rather than editing ~/.Xresources
# itself - this only needs to take effect for *this* session, and
# xrdb -merge is what makes it visible to xcb_cursor_context_new()
# immediately, before Zaris has even started.
if command -v xrdb >/dev/null 2>&1; then
    xrdb -merge <<EOF
Xcursor.theme: $_cursor_theme
Xcursor.size: $_cursor_size
EOF
fi

# GTK3/GTK4 settings.ini - surgical replace of just the two cursor keys,
# every other setting (theme name, icon theme, font, ...) left exactly as
# the user has it. Created fresh (with just these two keys under
# [Settings]) if the file doesn't exist yet at all; the two keys are
# appended under [Settings] if the file exists but doesn't have them yet.
_sync_gtk_settings() {
    local ini="$1"
    if [ ! -f "$ini" ]; then
        mkdir -p "$(dirname "$ini")"
        printf '[Settings]\ngtk-cursor-theme-name=%s\ngtk-cursor-theme-size=%s\n' "$_cursor_theme" "$_cursor_size" > "$ini"
        return
    fi

    if grep -q '^gtk-cursor-theme-name=' "$ini"; then
        sed -i "s/^gtk-cursor-theme-name=.*/gtk-cursor-theme-name=$_cursor_theme/" "$ini"
    else
        sed -i "/^\[Settings\]/a gtk-cursor-theme-name=$_cursor_theme" "$ini"
    fi

    if grep -q '^gtk-cursor-theme-size=' "$ini"; then
        sed -i "s/^gtk-cursor-theme-size=.*/gtk-cursor-theme-size=$_cursor_size/" "$ini"
    else
        sed -i "/^\[Settings\]/a gtk-cursor-theme-size=$_cursor_size" "$ini"
    fi
}

_sync_gtk_settings "$HOME/.config/gtk-3.0/settings.ini"
_sync_gtk_settings "$HOME/.config/gtk-4.0/settings.ini"

# Qt apps: no qt6ct.conf equivalent needed - Qt's own XCB platform plugin
# resolves cursor theme/size from XCURSOR_THEME/XCURSOR_SIZE directly
# (confirmed against qt6ct.conf's own real, minimal format on this
# machine - icon_theme is the only theming key it has at all, no cursor
# key exists there to set), the same env vars already exported above.

unset -f _sync_gtk_settings
unset _cursor_theme _cursor_size _ZARIS_CONF
