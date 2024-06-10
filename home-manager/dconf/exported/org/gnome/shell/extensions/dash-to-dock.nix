# Generated via dconf2nix: https://github.com/nix-commmunity/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/gnome/shell/extensions/dash-to-dock" = {
      background-color = "rgb(7,46,20)";
      background-opacity = 0.42;
      click-action = "focus-minimize-or-previews";
      custom-background-color = true;
      custom-theme-shrink = false;
      dash-max-icon-size = 48;
      disable-overview-on-startup = false;
      dock-fixed = false;
      dock-position = "BOTTOM";
      extend-height = false;
      height-fraction = 0.9;
      preferred-monitor = -2;
      preferred-monitor-by-connector = "DP-1";
      running-indicator-style = "DASHES";
      scroll-action = "switch-workspace";
      show-apps-at-top = true;
      show-mounts-network = false;
      show-mounts-only-mounted = true;
      show-trash = false;
      transparency-mode = "FIXED";
    };

  };
}
