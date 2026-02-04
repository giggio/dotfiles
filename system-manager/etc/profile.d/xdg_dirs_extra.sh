# making XDG directories explicity to their default values
# as per: https://specifications.freedesktop.org/basedir-spec/latest/ar01s03.html

if ! [ -v XDG_DATA_HOME ]; then
  export XDG_DATA_HOME=$HOME/.local/share
fi
if ! [ -v XDG_CONFIG_HOME ]; then
  export XDG_CONFIG_HOME=$HOME/.config
fi
if ! [ -v XDG_STATE_HOME ]; then
  export XDG_STATE_HOME=$HOME/.local/state
fi
if ! [ -v XDG_DATA_DIRS ]; then
  export XDG_DATA_DIRS=/usr/local/share/:/usr/share/
fi
if ! [ -v XDG_CONFIG_DIRS ]; then
  export XDG_CONFIG_DIRS=/etc/xdg
fi
if ! [ -v XDG_CACHE_HOME ]; then
  export XDG_CACHE_HOME=$HOME/.cache
fi
