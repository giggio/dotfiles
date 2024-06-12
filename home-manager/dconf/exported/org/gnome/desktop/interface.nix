# Generated via dconf2nix: https://github.com/nix-commmunity/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      clock-format = "12h";
      clock-show-seconds = true;
      clock-show-weekday = true;
      color-scheme = "prefer-dark";
      cursor-theme = "Adwaita";
      enable-hot-corners = false;
      gtk-theme = "Yaru-viridian-dark";
      icon-theme = "Yaru-viridian";
      locate-pointer = false;
    };

  };
}
