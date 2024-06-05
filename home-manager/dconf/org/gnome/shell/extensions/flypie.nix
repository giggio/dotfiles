# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/gnome/shell/extensions/flypie" = {
      active-stack-child = "achievements-page";
      child-color-mode-hover = "auto";
      menu-configuration = "[{\"name\":\"Example Menu\",\"icon\":\"flypie-symbolic-#46a\",\"shortcut\":\"<Primary>space\",\"centered\":false,\"id\":0,\"children\":[{\"name\":\"Sound\",\"icon\":\"flypie-multimedia-symbolic-#c86\",\"children\":[{\"name\":\"Mute\",\"icon\":\"flypie-multimedia-mute-symbolic-#853\",\"type\":\"Shortcut\",\"data\":\"AudioMute\",\"angle\":-1},{\"name\":\"Play / Pause\",\"icon\":\"flypie-multimedia-playpause-symbolic-#853\",\"type\":\"Shortcut\",\"data\":\"AudioPlay\",\"angle\":-1},{\"name\":\"Next Title\",\"icon\":\"flypie-multimedia-next-symbolic-#853\",\"type\":\"Shortcut\",\"data\":\"AudioNext\",\"angle\":90},{\"name\":\"Previous Title\",\"icon\":\"flypie-multimedia-previous-symbolic-#853\",\"type\":\"Shortcut\",\"data\":\"AudioPrev\",\"angle\":270}],\"type\":\"CustomMenu\",\"data\":{},\"angle\":-1},{\"name\":\"Favorites\",\"icon\":\"flypie-menu-favorites-symbolic-#da3\",\"type\":\"Favorites\",\"data\":{},\"angle\":-1},{\"name\":\"Next Workspace\",\"icon\":\"flypie-go-right-symbolic-#6b5\",\"type\":\"Shortcut\",\"data\":{\"shortcut\":\"<Control><Alt>Right\"},\"angle\":-1},{\"name\":\"Maximize Window\",\"icon\":\"flypie-window-maximize-symbolic-#b68\",\"type\":\"Shortcut\",\"data\":\"<Alt>F10\",\"angle\":-1},{\"name\":\"Fly-Pie Settings\",\"icon\":\"flypie-menu-system-symbolic-#3ab\",\"type\":\"Command\",\"data\":\"gnome-extensions prefs flypie@schneegans.github.com\",\"angle\":-1},{\"name\":\"Close Window\",\"icon\":\"flypie-window-close-symbolic-#a33\",\"type\":\"Shortcut\",\"data\":\"<Alt>F4\",\"angle\":-1},{\"name\":\"Previous Workspace\",\"icon\":\"flypie-go-left-symbolic-#6b5\",\"type\":\"Shortcut\",\"data\":{\"shortcut\":\"<Control><Alt>Left\"},\"angle\":-1},{\"name\":\"Running Apps\",\"icon\":\"flypie-menu-running-apps-symbolic-#65a\",\"type\":\"RunningApps\",\"data\":{\"activeWorkspaceOnly\":false,\"appGrouping\":true,\"hoverPeeking\":true,\"nameRegex\":\"\"},\"angle\":-1}],\"type\":\"CustomMenu\",\"data\":{}}]";
      stats-abortions = mkUint32 25;
      stats-achievement-dates = {
        cancellor0 = mkInt64 1717566641250;
        depth3-click-selector0 = 1717566731213;
        rookie = 1717566786740;
      };
      stats-best-tutorial-time = mkUint32 830;
      stats-click-selections-depth1 = mkUint32 2;
      stats-click-selections-depth2 = mkUint32 1;
      stats-click-selections-depth3 = mkUint32 33;
      stats-dbus-menus = mkUint32 57;
      stats-gesture-selections-depth1 = mkUint32 3;
      stats-gesture-selections-depth3 = mkUint32 1;
      stats-last-tutorial-time = mkUint32 983;
      stats-preview-menus = mkUint32 1;
      stats-selections = mkUint32 40;
      stats-selections-1000ms-depth1 = mkUint32 2;
      stats-selections-1000ms-depth3 = mkUint32 2;
      stats-selections-2000ms-depth3 = mkUint32 16;
      stats-selections-3000ms-depth3 = mkUint32 22;
      stats-settings-opened = mkUint32 1;
      stats-tutorial-menus = mkUint32 57;
      stats-unread-achievements = mkUint32 3;
    };

  };
}
