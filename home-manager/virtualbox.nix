{ lib, config, ... }:

lib.mkIf (config.setup.isVirtualBox) {
  dconf.settings."org/gnome/desktop/peripherals/mouse".natural-scroll = (lib.mkForce false);
}
