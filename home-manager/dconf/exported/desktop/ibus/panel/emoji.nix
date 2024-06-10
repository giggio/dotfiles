# Generated via dconf2nix: https://github.com/nix-commmunity/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "desktop/ibus/panel/emoji" = {
      unicode-hotkey = [ "<Control><Super><Shift>u" ];
    };

  };
}
