# Generated via dconf2nix: https://github.com/nix-commmunity/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/gnome/shell/extensions/clipboard-history" = {
      history-size = 300;
      toggle-menu = [ "<Super>v" ];
    };

  };
}
