# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/gnome/desktop/wm/keybindings" = {
      maximize = [];
      move-to-workspace-left = [ "<Shift><Super>k" ];
      move-to-workspace-right = [ "<Shift><Super>j" ];
      panel-run-dialog = [ "<Super>r" ];
      switch-to-workspace-left = [ "<Super>k" ];
      switch-to-workspace-right = [ "<Super>j" ];
      unmaximize = [];
    };

  };
}
