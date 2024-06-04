# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/gnome/desktop/applications/terminal" = {
      exec = "kitty";
      exec-arg = "";
    };

  };
}
