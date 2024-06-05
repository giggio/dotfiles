# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/gnome/shell/extensions/dash-to-dock" = {
      always-center-icons = true;
      apply-custom-theme = false;
      background-color = "rgb(7,46,20)";
      background-opacity = 0.77;
      click-action = "minimize";
      custom-background-color = true;
      custom-theme-shrink = false;
      dash-max-icon-size = 48;
      dock-fixed = false;
      dock-position = "BOTTOM";
      extend-height = false;
      height-fraction = 0.9;
      hide-tooltip = false;
      icon-size-fixed = false;
      isolate-monitors = false;
      max-alpha = 0.8;
      preferred-monitor = -2;
      preferred-monitor-by-connector = "DP-1";
      preview-size-scale = 0.0;
      running-indicator-style = "DASHES";
      scroll-action = "switch-workspace";
      show-apps-at-top = true;
      show-icons-emblems = false;
      show-mounts = true;
      show-mounts-network = false;
      show-mounts-only-mounted = true;
      show-trash = false;
      transparency-mode = "FIXED";
    };

  };
}
