{
  setup,
  pkgs,
  config,
  ...
}:

{
  systemd = {
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
          commonServices = {
            nix-metadata-update = {
              Unit = {
                Description = "Caches nix metadata";
                StartLimitIntervalSec = "infinity";
                StartLimitBurst = 5;
              };
              Service = {
                Type = "oneshot";
                ExecStart = "${pkgs.nix}/bin/nix flake metadata nixpkgs";
                Restart = "on-failure";
                RestartMaxDelaySec = "1m";
                RestartSec = "1s";
                RestartSteps = 3;
              };
            };
          };
          otherServices =
            if !setup.wsl then
              {
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
                docker =
                  let
                    settingsFormat = pkgs.formats.json { };
                    daemonSettingsFile = settingsFormat.generate "daemon.json" {
                      "data-root" = "/var/lib/docker-giggio"; # because the storage-driver can't run on ecryptfs which by default lives on a subdirectory of the home dir
                      "storage-driver" = "btrfs"; # to match my filesystem and get the best performance
                    };
                  in
                  {
                    # adapted from https://github.com/NixOS/nixpkgs/blob/fabb8c9/nixos/modules/virtualisation/docker-rootless.nix
                    Install = {
                      WantedBy = [ "default.target" ];
                    };
                    Unit = {
                      Description = "Docker Application Container Engine (Rootless)";
                      # docker-rootless doesn't support running as root.
                      ConditionUser = "!root";
                      StartLimitInterval = "60s";
                      StartLimitBurst = 3;
                    };
                    Service = {
                      Environment = "PATH=/usr/bin"; # needs newuidmap
                      Type = "notify";
                      ExecStart = "${pkgs.docker}/bin/dockerd-rootless --config-file=${daemonSettingsFile}";
                      ExecReload = "${pkgs.procps}/bin/kill -s HUP $MAINPID";
                      TimeoutSec = 0;
                      RestartSec = 2;
                      Restart = "always";
                      LimitNOFILE = "infinity";
                      LimitNPROC = "infinity";
                      LimitCORE = "infinity";
                      Delegate = true;
                      NotifyAccess = "all";
                      KillMode = "mixed";
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

      timers =
        let
          all = {
            nix-metadata-update = {
              Unit = {
                Description = "Caches nix metadata";
              };
              Timer = {
                OnCalendar = "*-*-* 0/1:00:00";
              };
              Install = {
                WantedBy = [ "graphical-session.target" ];
              };
            };
          };
          wsl = if setup.wsl then { } else { };
        in
        all // wsl;

      tmpfiles.rules = [
        "d ${config.home.homeDirectory}/.ssh/config.d/ 0700 ${config.home.username} ${config.home.username} -"
      ];
    };
  };
}
