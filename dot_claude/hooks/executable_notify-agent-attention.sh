#!/bin/sh
set -u

run_if_available() {
  command -v "$1" >/dev/null 2>&1 || return 1
  "$@" >/dev/null 2>&1
}

is_wsl() {
  grep -qi microsoft /proc/version 2>/dev/null
}

case "$(uname -s 2>/dev/null || printf unknown)" in
  Darwin)
    run_if_available afplay /System/Library/Sounds/Ping.aiff && exit 0
    run_if_available osascript -e 'beep 1' && exit 0
    ;;
  Linux)
    if is_wsl; then
      run_if_available powershell.exe -NoProfile -Command '(New-Object Media.SoundPlayer "C:\Windows\Media\Windows Unlock.wav").PlaySync()' && exit 0
      run_if_available powershell.exe -NoProfile -Command '(New-Object Media.SoundPlayer "C:\Windows\Media\Windows Notify System Generic.wav").PlaySync()' && exit 0
      run_if_available powershell.exe -NoProfile -Command '(New-Object Media.SoundPlayer "C:\Windows\Media\Windows Proximity Notification.wav").PlaySync()' && exit 0
    fi

    run_if_available paplay /usr/share/sounds/freedesktop/stereo/message-new-instant.oga && exit 0
    run_if_available paplay /usr/share/sounds/freedesktop/stereo/complete.oga && exit 0
    run_if_available canberra-gtk-play -i message-new-instant && exit 0
    run_if_available canberra-gtk-play -i complete && exit 0
    run_if_available play -q -n synth 0.18 sine 660 vol 0.20 && exit 0
    run_if_available speaker-test -t sine -f 660 -l 1 && exit 0
    ;;
esac

{ printf '\a' >/dev/tty; } 2>/dev/null || printf '\a'
exit 0
