{
  imports = [
    ./apps/psensor.nix
    ./org/gnome/desktop/datetime.nix
    ./org/gnome/desktop/interface.nix
    ./org/gnome/desktop/input-sources.nix
    ./org/gnome/desktop/peripherals/mouse.nix
    ./org/gnome/desktop/wm/keybindings.nix
    ./org/gnome/shell/extensions/clipboard-history.nix
    ./org/gnome/shell/extensions/dash-to-dock.nix
    ./org/gnome/shell/keybindings.nix
    ./org/gnome/settings-daemon/plugins.nix
    ./desktop/ibus/panel/emoji.nix
  ];
}
