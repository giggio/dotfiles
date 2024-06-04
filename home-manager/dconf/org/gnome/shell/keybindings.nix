# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/gnome/shell/keybindings" = {
      screenshot = [ "Print" ];
      show-screenshot-ui = [ "<Shift><Super>s" ];
      toggle-message-tray = [];
    };

  };
}
