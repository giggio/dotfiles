# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/gnome/shell/extensions/wsmatrix" = {
      num-columns = 2;
      wraparound-mode = "none";
    };

  };
}
