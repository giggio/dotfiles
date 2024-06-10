# Generated via dconf2nix: https://github.com/nix-commmunity/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/gnome/shell/extensions/hibernate-status-button" = {
      show-hibernate = false;
      show-suspend = true;
    };

  };
}
