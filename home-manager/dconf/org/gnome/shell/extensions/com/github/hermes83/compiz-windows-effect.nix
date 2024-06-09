# Generated via dconf2nix: https://github.com/nix-commmunity/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/gnome/shell/extensions/com/github/hermes83/compiz-windows-effect" = {
      friction = 3.4;
      mass = 71.0;
      resize-effect = true;
      speedup-factor-divider = 12.1;
      spring-k = 4.0;
    };

  };
}
