#!/bin/sh
# HONOR MagicBook Pro 14 AI (ZQC-P / M1010) — restore Fn+F7 mic-mute keymap
# after suspend/hibernate. atkbd reinitializes serio0 on resume and the
# scancode→keycode mapping is lost; setkeycodes reapplies it.
#
# Installed at /usr/lib/systemd/system-sleep/ and invoked by systemd-sleep(8)
# with $1 = pre|post and $2 = suspend|hibernate|hybrid-sleep|...
case "$1" in
    post)
        /usr/bin/setkeycodes e078 248 || true
        ;;
esac
