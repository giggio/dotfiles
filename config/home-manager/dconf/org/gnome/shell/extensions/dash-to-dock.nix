# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/gnome/shell/extensions/dash-to-dock" = {
      click-action = "minimize";
      show-icons-emblems = false;
    };

  };
}
