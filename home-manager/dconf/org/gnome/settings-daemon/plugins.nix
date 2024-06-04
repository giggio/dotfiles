# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/gnome/settings-daemon/plugins/media-keys" = {
      home = [ "<Super>e" ];
    };

    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-timeout = 1800;
      sleep-inactive-ac-type = "suspend";
    };

  };
}
