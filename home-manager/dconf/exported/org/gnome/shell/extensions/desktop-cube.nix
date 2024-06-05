# Generated via dconf2nix: https://github.com/nix-commmunity/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/gnome/shell/extensions/desktop-cube" = {
      background-panorama = "/home/giggio/Downloads/beach_cloudy_bridge.jpg";
      enable-panel-dragging = false;
      per-monitor-perspective = true;
      window-parallax = 0.531746;
    };

  };
}
