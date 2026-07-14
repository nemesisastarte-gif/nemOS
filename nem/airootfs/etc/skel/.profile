# nemOS - User Profile
# Sourced by login shells and display managers

# ---- Locale ----
export LANG=fr_FR.UTF-8
export LANGUAGE=fr_FR:fr:en_US:en
export LC_ALL=fr_FR.UTF-8
export LC_COLLATE=C
export LC_NUMERIC=fr_FR.UTF-8
export LC_TIME=fr_FR.UTF-8
export LC_MONETARY=fr_FR.UTF-8
export LC_MEASUREMENT=fr_FR.UTF-8
export LC_PAPER=fr_FR.UTF-8

# ---- PATH ----
export PATH="${HOME}/bin:${HOME}/.local/bin:${PATH}"

# ---- NemOS Environment Variables ----
export NEMOS_VERSION="1.0"
export NEMOS_HOME="/usr/share/nemos"
export NEMOS_CONFIG="${HOME}/.config/nemos"
export NEMOS_CACHE="${HOME}/.cache/nemos"
export NEMOS_DATA="${HOME}/.local/share/nemos"

# Create NemOS directories if they don't exist
mkdir -p "${NEMOS_CONFIG}" "${NEMOS_CACHE}" "${NEMOS_DATA}" "${HOME}/bin" "${HOME}/.local/bin"

# ---- Desktop Environment ----
export XDG_CURRENT_DESKTOP=nemOS
export XDG_SESSION_DESKTOP=nemOS
export DESKTOP_SESSION=nemOS

# ---- GTK Theme ----
export GTK_THEME=NemOS-Dark
export GTK2_RC_FILES="${HOME}/.gtkrc-2.0"
export GTK_IM_MODULE=xim

# ---- Qt Theme ----
export QT_QPA_PLATFORMTHEME=gtk2
export QT_STYLE_OVERRIDE=gtk2

# ---- Qt5 Wayland bridge (not used on X11 but safe to set) ----
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1

# ---- XDG Directories ----
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_STATE_HOME="${HOME}/.local/state"
export XDG_DATA_DIRS="/usr/local/share:/usr/share"
export XDG_CONFIG_DIRS="/etc/xdg"

# ---- Editor ----
export EDITOR=geany
export VISUAL=geany
export PAGER=less

# ---- Browser ----
export BROWSER=firefox-esr

# ---- Terminal ----
export TERMINAL=xfce4-terminal

# ---- Less ----
export LESS="-R -M --shift 2"
export LESSCHARSET="utf-8"
export LESSHISTFILE="${NEMOS_CACHE}/lesshst"

# ---- Input Method (if ibus is installed) ----
if command -v ibus-daemon > /dev/null 2>&1; then
    export GTK_IM_MODULE=ibus
    export XMODIFIERS=@im=ibus
    export QT_IM_MODULE=ibus
fi

# ---- Java ----
export _JAVA_OPTIONS="-Dawt.useSystemAAFontSettings=on -Dswing.aatext=true"

# ---- SSH Agent ----
if [ -z "$SSH_AGENT_PID" ] && [ -n "$DISPLAY" ]; then
    if command -v ssh-agent > /dev/null 2>&1; then
        eval "$(ssh-agent -s)" > /dev/null 2>&1
    fi
fi

# ---- GPG Agent ----
GPG_TTY=$(tty 2>/dev/null)
export GPG_TTY
export GPG_AGENT_INFO=""

# ---- Aliases ----
alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -I'
alias mkdir='mkdir -p'
alias h='history'
alias ..='cd ..'
alias ...='cd ../..'
alias cls='clear'
alias updates='sudo apt update && sudo apt full-upgrade'

# ---- NemOS welcome message ----
if [ -z "$NEMOS_WELCOME_SHOWN" ] && [ -t 0 ]; then
    if [ -f /etc/nemos-release ]; then
        cat /etc/nemos-release 2>/dev/null
    fi
    export NEMOS_WELCOME_SHOWN=1
fi