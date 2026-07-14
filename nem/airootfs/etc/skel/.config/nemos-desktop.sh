#!/bin/bash
# nemOS desktop session startup script
# Launched via autostart or .xinitrc

# Wait for X to be fully ready
sleep 1

# Set X resources (if available)
if [ -f "$HOME/.Xresources" ]; then
    xrdb -merge "$HOME/.Xresources"
fi

# Set GTK/Qt theming
export GTK_THEME=NemOS-Dark
export QT_QPA_PLATFORMTHEME=gtk2
export XDG_CURRENT_DESKTOP=nemOS
export XDG_SESSION_DESKTOP=nemOS
export DESKTOP_SESSION=nemOS

# Start composite manager for transparency and rounded corners
if ! pgrep -x "xcompmgr" > /dev/null 2>&1; then
    xcompmgr -c -C -t-5 -l-5 -r4.2 -o.5 -D 5 &
fi

# Start tint2 top bar
if ! pgrep -x "tint2" > /dev/null 2>&1; then
    tint2 &
fi

# Start vala-panel-appmenu (global menu bar)
if command -v vala-panel-appmenu-registrar > /dev/null 2>&1; then
    if ! pgrep -f "vala-panel-appmenu-registrar" > /dev/null 2>&1; then
        vala-panel-appmenu-registrar &
    fi
fi

# Start Plank dock
if ! pgrep -x "plank" > /dev/null 2>&1; then
    plank &
fi

# Start volume icon in systray
if command -v volumeicon > /dev/null 2>&1; then
    if ! pgrep -x "volumeicon" > /dev/null 2>&1; then
        volumeicon &
    fi
fi

# Start network applet in systray (nm-applet)
if command -v nm-applet > /dev/null 2>&1; then
    if ! pgrep -x "nm-applet" > /dev/null 2>&1; then
        nm-applet --sm-disable &
    fi
fi

# Start light-locker for screen locking
if command -v light-locker > /dev/null 2>&1; then
    if ! pgrep -x "light-locker" > /dev/null 2>&1; then
        light-locker --lock-on-suspend --lock-on-lid --lock-after-screensaver=300 &
    fi
fi

# Start notification daemon
if command -v dunst > /dev/null 2>&1; then
    if ! pgrep -x "dunst" > /dev/null 2>&1; then
        dunst -config "$HOME/.config/dunst/dunstrc" 2>/dev/null &
    fi
fi

# Set wallpaper (use feh or nitrogen)
if command -v feh > /dev/null 2>&1; then
    if [ -f "$HOME/.config/nemos/wallpaper.png" ]; then
        feh --bg-scale "$HOME/.config/nemos/wallpaper.png" 2>/dev/null
    elif [ -f "/usr/share/backgrounds/nemos/wallpaper.png" ]; then
        feh --bg-scale "/usr/share/backgrounds/nemos/wallpaper.png" 2>/dev/null
    else
        # Set a solid dark color as fallback
        xsetroot -solid "#1E1E2E"
    fi
elif command -v nitrogen > /dev/null 2>&1; then
    nitrogen --restore 2>/dev/null || xsetroot -solid "#1E1E2E"
else
    xsetroot -solid "#1E1E2E"
fi

# Start Openbox as the window manager
exec openbox --startup "$HOME/.config/openbox/nemOS-oberc.xml"