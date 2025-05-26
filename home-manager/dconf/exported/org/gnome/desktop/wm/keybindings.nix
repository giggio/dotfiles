# Generated via dconf2nix: https://github.com/nix-commmunity/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/gnome/desktop/wm/keybindings" = {
      maximize = [ "<Super>k" ];
      move-to-monitor-down = [ "<Shift><Super>j" ];
      move-to-monitor-left = [ "<Shift><Super>h" ];
      move-to-monitor-right = [ "<Shift><Super>l" ];
      move-to-monitor-up = [ "<Shift><Super>k" ];
      move-to-workspace-down = [ "<Shift><Control><Alt><Super>j" ];
      move-to-workspace-left = [ "<Shift><Control><Alt><Super>h" ];
      move-to-workspace-right = [ "<Shift><Control><Alt><Super>l" ];
      move-to-workspace-up = [ "<Shift><Control><Alt><Super>k" ];
      panel-run-dialog = [ "<Super>r" ];
      switch-to-workspace-down = [ "<Shift><Control><Super>j" ];
      switch-to-workspace-left = [ "<Shift><Control><Super>h" ];
      switch-to-workspace-right = [ "<Shift><Control><Super>l" ];
      switch-to-workspace-up = [ "<Shift><Control><Super>k" ];
      unmaximize = [ ];
    };

  };
}
