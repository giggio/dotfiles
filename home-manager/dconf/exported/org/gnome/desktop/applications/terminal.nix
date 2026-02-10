# Generated via dconf2nix: https://github.com/nix-commmunity/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/gnome/desktop/applications/terminal" = {
      exec = "ghostty";
      exec-arg = "";
    };

  };
}
