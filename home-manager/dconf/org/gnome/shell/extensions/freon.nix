# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/gnome/shell/extensions/freon" = {
      hot-sensors = [ "CPU Package" ];
      show-decimal-value = true;
      use-generic-lmsensors = true;
      use-gpu-aticonfig = false;
    };

  };
}
