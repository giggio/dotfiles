{ lib, setup, ... }:

lib.mkIf (setup.isVirtualBox) {
  dconf.settings."org/gnome/desktop/peripherals/mouse".natural-scroll = (lib.mkForce false);
}
