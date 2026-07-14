#!/bin/bash
# nemOS - ~/.xinitrc
# Start X session with compositing, tint2, plank, and openbox

# Load X resources
if [ -f "$HOME/.Xresources" ]; then
    xrdb -merge "$HOME/.Xresources"
fi

# Set environment
export GTK_THEME=NemOS-Dark
export QT_QPA_PLATFORMTHEME=gtk2
export XDG_CURRENT_DESKTOP=nemOS
export XDG_SESSION_DESKTOP=nemOS
export DESKTOP_SESSION=nemOS

# Disable X screensaver and DPMS (we handle locking ourselves)
xset s off
xset -dpms
xset s noblank

# Set keyboard repeat rate
xset r rate 300 30

# Set cursor theme
if [ -d /usr/share/icons/Adwaita/cursors ]; then
    xsetroot -cursor_name left_ptr
fi

# Start composite manager (xcompmgr) for transparency, shadows, rounded corners
# Options: -c = client-side shadows, -C = avoid shadows on drag, 
#          -t-5 = top shadow offset, -l-5 = left shadow offset,
#          -r4.2 = shadow blur radius, -o.5 = shadow opacity, -D 5 = fade duration
xcompmgr -c -C -t-5 -l-5 -r4.2 -o.5 -D 5 &

# Wait briefly for compositor to initialize
sleep 0.5

# Start tint2 top bar panel
tint2 &

# Start vala-panel-appmenu (global menu bar in tint2)
if command -v vala-panel-appmenu-registrar > /dev/null 2>&1; then
    vala-panel-appmenu-registrar &
fi

# Start Plank dock (macOS-like dock at bottom)
plank &

# Start volumeicon for systray volume control
if command -v volumeicon > /dev/null 2>&1; then
    volumeicon &
fi

# Start NetworkManager applet for systray
if command -v nm-applet > /dev/null 2>&1; then
    nm-applet --sm-disable &
fi

# Start light-locker
if command -v light-locker > /dev/null 2>&1; then
    light-locker --lock-on-suspend --lock-on-lid --lock-after-screensaver=300 &
fi

# Start notification daemon (dunst)
if command -v dunst > /dev/null 2>&1; then
    if [ -f "$HOME/.config/dunst/dunstrc" ]; then
        dunst -config "$HOME/.config/dunst/dunstrc" &
    else
        dunst &
    fi
fi

# Set wallpaper
if command -v feh > /dev/null 2>&1; then
    if [ -f "$HOME/.config/nemos/wallpaper.png" ]; then
        feh --bg-scale "$HOME/.config/nemos/wallpaper.png" 2>/dev/null
    elif [ -f "/usr/share/backgrounds/nemos/wallpaper.png" ]; then
        feh --bg-scale "/usr/share/backgrounds/nemos/wallpaper.png" 2>/dev/null
    else
        xsetroot -solid "#1E1E2E"
    fi
elif command -v nitrogen > /dev/null 2>&1; then
    nitrogen --restore 2>/dev/null || xsetroot -solid "#1E1E2E"
else
    xsetroot -solid "#1E1E2E"
fi

# Start Power Manager (for battery, brightness, etc.)
if command -v xfce4-power-manager > /dev/null 2>&1; then
    xfce4-power-manager --sm-disable &
fi

# Launch polkit agent for authentication (handles pkexec, etc.)
if command -v lxpolkit > /dev/null 2>&1; then
    lxpolkit &
elif [ -x /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 ]; then
    /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 &
elif [ -x /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 ]; then
    /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
fi

# Ensure the dock and panel are above everything else
sleep 1

# Finally, start Openbox as the window manager (this blocks until exit)
# The --startup flag runs the menu.xml file
if [ -f "$HOME/.config/openbox/nemOS-oberc.xml" ]; then
    # Copy the custom menu as the default menu.xml if not already present
    if [ ! -f "$HOME/.config/openbox/menu.xml" ]; then
        cp "$HOME/.config/openbox/nemOS-oberc.xml" "$HOME/.config/openbox/menu.xml"
    fi
fi

exec openbox