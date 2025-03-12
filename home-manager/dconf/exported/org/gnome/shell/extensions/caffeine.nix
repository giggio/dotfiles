# Generated via dconf2nix: https://github.com/nix-commmunity/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/gnome/shell/extensions/caffeine" = {
      countdown-timer = 1800;
      duration-timer = 2;
      enable-fullscreen = false;
      indicator-position-max = 3;
      restore-state = false;
      screen-blank = "always";
      toggle-state = false;
      user-enabled = false;
    };

  };
}
