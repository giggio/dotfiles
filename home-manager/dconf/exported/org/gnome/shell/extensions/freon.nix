# Generated via dconf2nix: https://github.com/nix-commmunity/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/gnome/shell/extensions/freon" = {
      group-temperature = true;
      group-voltage = true;
      hot-sensors = [ "Tctl" ];
      panel-box-index = 0;
      show-decimal-value = true;
      show-icon-on-panel = true;
      show-rotationrate = true;
      show-temperature = true;
      show-temperature-unit = true;
      show-voltage-unit = true;
      unit = 0;
      update-time = 5;
      use-drive-smartctl = false;
      use-generic-liquidctl = false;
      use-generic-lmsensors = true;
      use-gpu-aticonfig = false;
    };

  };
}
