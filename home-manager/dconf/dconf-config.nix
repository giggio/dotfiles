{ pkgs, lib, ... }:

{
  dconf = {
    enable = true;
    settings = {
      "org/gnome/shell" = {
        disable-user-extensions = false;
        enabled-extensions = with pkgs.gnomeExtensions; [
          blur-my-shell.extensionUuid
          burn-my-windows.extensionUuid
          caffeine.extensionUuid
          clipboard-history.extensionUuid
          compiz-alike-magic-lamp-effect.extensionUuid
          compiz-windows-effect.extensionUuid
          fly-pie.extensionUuid
          freon.extensionUuid
          gsconnect.extensionUuid
          hibernate-status-button.extensionUuid
          workspace-matrix.extensionUuid
          smart-auto-move.extensionUuid
          smile-complementary-extension.extensionUuid
        ];
      };
      "org/gnome/shell/extensions/burn-my-windows" = {
        active-profile = (lib.mkForce "/home/giggio/.config/burn-my-windows/profiles/open.conf");
      };
      "org/gnome/desktop/wm/keybindings" = {
        maximize = (lib.mkForce [ "<Super>k" ]);
      };
    };
  };
}
