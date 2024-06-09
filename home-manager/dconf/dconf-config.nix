{ pkgs, ... }:

{
  dconf = {
    enable = true;
    settings."org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = with pkgs.gnomeExtensions; [
        blur-my-shell.extensionUuid
        burn-my-windows.extensionUuid
        clipboard-history.extensionUuid
        compiz-alike-magic-lamp-effect.extensionUuid
        compiz-windows-effect.extensionUuid
        fly-pie.extensionUuid
        freon.extensionUuid
        gsconnect.extensionUuid
        hibernate-status-button.extensionUuid
        workspace-matrix.extensionUuid
      ];
    };
  };
}
