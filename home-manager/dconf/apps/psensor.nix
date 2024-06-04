# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "apps/psensor" = {
      graph-alpha-channel-enabled = false;
      graph-background-alpha = 1.0;
      graph-background-color = "#e8f4e8f4a8f5";
      graph-foreground-color = "#000000000000";
      graph-monitoring-duration = 5;
      graph-smooth-curves-enabled = true;
      graph-update-interval = 1;
      interface-hide-on-startup = false;
      interface-menu-bar-disabled = false;
      interface-sensorlist-position = 0;
      interface-temperature-unit = 0;
      interface-unity-launcher-count-disabled = false;
      interface-window-decoration-disabled = false;
      interface-window-divider-pos = 1384;
      interface-window-h = 1011;
      interface-window-keep-below-enabled = false;
      interface-window-restore-enabled = true;
      interface-window-w = 1854;
      interface-window-x = 0;
      interface-window-y = 0;
      notif-script = "";
      provider-atiadlsdk-enabled = true;
      provider-gtop2-enabled = true;
      provider-hddtemp-enabled = false;
      provider-libatasmart-enabled = false;
      provider-lmsensors-enabled = true;
      provider-nvctrl-enabled = false;
      provider-udisks2-enabled = true;
      sensor-update-interval = 2;
      slog-enabled = false;
      slog-interval = 300;
    };

  };
}
