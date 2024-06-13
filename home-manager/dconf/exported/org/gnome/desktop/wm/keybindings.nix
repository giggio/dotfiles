# Generated via dconf2nix: https://github.com/nix-commmunity/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/gnome/desktop/wm/keybindings" = {
      maximize = [ ];
      move-to-monitor-down = [ "<Shift><Super>j" ];
      move-to-monitor-left = [ "<Shift><Super>h" ];
      move-to-monitor-right = [ "<Shift><Super>l" ];
      move-to-monitor-up = [ "<Shift><Super>k" ];
      move-to-workspace-down = [ "<Control><Shift><Alt>j" ];
      move-to-workspace-left = [ "<Control><Shift><Alt>h" ];
      move-to-workspace-right = [ "<Control><Shift><Alt>j" ];
      move-to-workspace-up = [ "<Control><Shift><Alt>k" ];
      panel-run-dialog = [ "<Super>r" ];
      switch-to-workspace-down = [ "<Control><Alt>j" ];
      switch-to-workspace-left = [ "<Control><Alt>h" ];
      switch-to-workspace-right = [ "<Control><Alt>l" ];
      switch-to-workspace-up = [ "<Control><Alt>k" ];
      unmaximize = [ ];
    };

  };
}
