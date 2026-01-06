{ setup, pkgs, ... }:

{
  user = {
    settings = {
      Manager = {
        ManagerEnvironment = {
          XDG_DATA_DIRS = "%u/.local/share:%u/.local/share/flatpak/exports/share:%u/.nix-profile/share:/nix/var/nix/profiles/default/share:/usr/local/share/:/usr/share/:/usr/share/gnome:/usr/share/ubuntu:/var/lib/flatpak/exports/share:/var/lib/snapd/desktop";
          PATH = "/bin:%u/.local/bin:%u/.local/share/npm/bin:%u/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/sbin:/snap/bin:/usr/bin:/usr/games:/usr/local/bin:/usr/local/games:/usr/local/sbin:/usr/sbin";
        };
        DefaultEnvironment = {
          XDG_DATA_DIRS = "%u/.local/share:%u/.local/share/flatpak/exports/share:%u/.nix-profile/share:/nix/var/nix/profiles/default/share:/usr/local/share/:/usr/share/:/usr/share/gnome:/usr/share/ubuntu:/var/lib/flatpak/exports/share:/var/lib/snapd/desktop";
          PATH = "/bin:%u/.local/bin:%u/.local/share/npm/bin:%u/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/sbin:/snap/bin:/usr/bin:/usr/games:/usr/local/bin:/usr/local/games:/usr/local/sbin:/usr/sbin";
        };
      };
    };
    startServices = "sd-switch";
    targets =
      let
        commonTargets = { };
        otherTargets =
          if !setup.wsl then
            { }
          else
            {
              wsl-forward-gpg-all = {
                Unit = {
                  Description = "Forward gpg, gpg-extra and ssh to Windows";
                  Wants = [
                    "wsl-forward-gpg.socket"
                    "wsl-forward-gpg-extra.socket"
                    "wsl-forward-ssh.socket"
                  ];
                };
                Install = {
                  WantedBy = [ "default.target" ];
                };
              };
            };
      in
      commonTargets // otherTargets;
    services =
      let
        commonServices = { };
        otherServices =
          if !setup.wsl then
            {
              ulauncher = {
                Unit = {
                  Description = "Linux Application Launcher";
                  Documentation = "https://ulauncher.io/";
                };
                Service = {
                  Type = "simple";
                  Restart = "always";
                  RestartSec = 1;
                  ExecStart = "env GDK_BACKEND=x11 ${pkgs.ulauncher}/bin/ulauncher --hide-window";
                };
                Install = {
                  WantedBy = [ "graphical-session.target" ];
                };
              };
              mount-data = {
                Unit = {
                  Description = "Mount private and ecrypted directory";
                };
                Service = {
                  ExecStart = [ "${./systemd/mount-data}" ];
                  StandardOutput = "journal";
                  Type = "simple";
                };
                Install = {
                  WantedBy = [ "default.target" ];
                };
              };
            }
          else
            {
              "wsl-forward-gpg-extra@" = {
                Unit = {
                  Description = "Forward gpg extra to Windows";
                  Requires = "wsl-forward-gpg-extra.socket";
                  After = "network-online.target";
                  Wants = "network-online.target";
                };
                Service = {
                  ExecStart = "${./systemd/wsl-forward-gpg} --gpg-extra --instance %i";
                };
              };
              "wsl-forward-gpg@" = {
                Unit = {
                  Description = "Forward gpg to Windows";
                  Requires = "wsl-forward-gpg.socket";
                  After = "network-online.target";
                  Wants = "network-online.target";
                };
                Service = {
                  ExecStart = "${./systemd/wsl-forward-gpg} --gpg --instance %i";
                };
              };
              "wsl-forward-ssh@" = {
                Unit = {
                  Description = "Forward ssh to Windows";
                  Requires = "wsl-forward-ssh.socket";
                  After = "network-online.target";
                  Wants = "network-online.target";
                };
                Service = {
                  ExecStart = "${./systemd/wsl-forward-gpg} --ssh --instance %i";
                };
              };
            };
      in
      commonServices // otherServices;
    sockets =
      let
        commonSockets = { };
        otherSockets =
          if !setup.wsl then
            { }
          else
            {
              wsl-forward-gpg-extra = {
                Unit = {
                  Description = "Forward gpg extra socket to Windows";
                  PartOf = "wsl-forward-gpg-all.target";
                };
                Socket = {
                  # %t is XDG_RUNTIME_DIR
                  ListenStream = "%t/gnupg/S.gpg-agent.extra";
                  SocketMode = "0600";
                  DirectoryMode = "0700";
                  Accept = "yes";
                };
                Install = {
                  WantedBy = [ "sockets.target" ];
                };
              };
              wsl-forward-gpg = {
                Unit = {
                  Description = "Forward gpg socket to Windows";
                  PartOf = "wsl-forward-gpg-all.target";
                };
                Socket = {
                  # %t is XDG_RUNTIME_DIR
                  ListenStream = "%t/gnupg/S.gpg-agent";
                  SocketMode = "0600";
                  DirectoryMode = "0700";
                  Accept = "yes";
                };
                Install = {
                  WantedBy = [ "sockets.target" ];
                };
              };
              wsl-forward-ssh = {
                Unit = {
                  Description = "Forward ssh socket to Windows";
                  PartOf = "wsl-forward-gpg-all.target";
                };
                Socket = {
                  # %t is XDG_RUNTIME_DIR
                  ListenStream = "%t/gnupg/ssh.sock";
                  SocketMode = "0600";
                  DirectoryMode = "0700";
                  Accept = "yes";
                };
                Install = {
                  WantedBy = [ "sockets.target" ];
                };

              };
            };
      in
      commonSockets // otherSockets;
  };
}
