{
  lib,
  pkgs,
  config,
  system,
  inputs,
  ...
}:
{
  config =
    let
      system-manager = inputs.system-manager;
      username = "giggio";
    in
    {
      nixpkgs.hostPlatform = "x86_64-linux";

      users = {
        users.${username} = {
          extraGroups = [
            "i2c"
            "kvm"
            "libvirt"
            "sudo"
            "users"
          ];
          isNormalUser = true;
          shell = "/bin/bash";
          group = username;
          description = "Giovanni Bassi,,,";
        };
        groups = {
          ${username} = { };
          i2c = { };
          kvm = { };
          libvirt = { };
          sudo = { };
          users = { };
        };
      };

      services = { };

      environment = {
        systemPackages =
          with pkgs;
          let
            # rust-toolchain-fenix # see pkgs/default.nix # commented out, takes too long to build, will add back if needed
            all = (
              # SystemManager only basic packages
              [
                system-manager.packages.${system}.default # system-manager binary
              ]
              # end of SystemManager only basic packages
              # SystemManager basic packages shared with Home Manager
              ++ [
                bat # A cat clone with wings  https://github.com/sharkdp/bat
                cachix # install cache, for example, with: $HOME/.nix-profile/bin/cachix use nix-community
                colorized-logs # Tools for logs with ANSI color https://github.com/kilobyte/colorized-logs
                curlFull # Command line tool for transferring files with URL syntax https://curl.se/
                delta # Syntax-highlighting pager for git and diff output https://github.com/dandavison/delta
                efibootmgr # Linux user-space application to modify the Intel Extensible Firmware Interface (EFI) Boot Manager https://github.com/rhboot/efibootmgr
                eza # Modern replacement for ls https://github.com/eza-community/eza
                fd # Simple, fast and user-friendly alternative to find https://github.com/sharkdp/fd
                file # Program that shows the type of files https://darwinsys.com/file/
                fzf # Command-line fuzzy finder https://github.com/junegunn/fzf
                gcc # GNU Compiler Collection https://gcc.gnu.org/
                ghostty.terminfo # Fast, native, feature-rich terminal emulator pushing modern features
                git # Distributed version control system https://git-scm.com/
                gnumake # Tool which controls the generation of executables and other non-source files https://www.gnu.org/software/make/
                gnupg # Modern release of the GNU Privacy Guard, a GPL OpenPGP implementation https://gnupg.org/
                htop # Interactive process viewer https://htop.dev/
                inetutils # Collection of common network programs https://www.gnu.org/software/inetutils/
                iproute2 # Collection of utilities for controlling TCP/IP networking and traffic control in Linux https://wiki.linuxfoundation.org/networking/iproute2
                jq # Lightweight and flexible command-line JSON processor https://jqlang.github.io/jq/
                lm_sensors # Tools for reading hardware sensors - maintained fork https://github.com/hramrach/lm-sensors https://archive.kernel.org/oldwiki/hwmon.wiki.kernel.org/lm_sensors.html
                neovim # Vim-fork focused on extensibility and agility https://neovim.io
                net-tools # Set of tools for controlling the network subsystem in Linux https://sourceforge.net/projects/net-tools/
                procs # A modern replacement for ps written in Rust https://github.com/dalance/procs
                tree # Command to produce a depth indented directory listing https://mama.indstate.edu/users/ice/tree/
                tree-sitter # An incremental parsing system for programming tools https://github.com/tree-sitter/tree-sitter
                vim-full # Most popular clone of the VI editor https://www.vim.org/
                wget # Tool for retrieving files using HTTP, HTTPS, FTP and FTPS https://www.gnu.org/software/wget/
                zellij # Terminal workspace with batteries included https://zellij.dev/
              ]
              ++ (with unixtools; [
                arp
                netstat
                route
              ])
              # end of SystemManager basic packages shared with Home Manager
            );
            rog2 = lib.lists.optionals (config.setup.hostname == "rog2") ([
              liquidctl # Cross-platform CLI and Python drivers for AIO liquid coolers and other devices https://github.com/liquidctl/liquidctl
              coolercontrol.coolercontrold # Monitor and control your cooling devices (Main Daemon) https://gitlab.com/coolercontrol/coolercontrol
            ]);
          in
          all ++ rog2;
        # Add directories and files to `/etc` and set their permissions
        etc =
          let
            all = {
              "systemd/logind.conf".source = ./etc/systemd/logind.conf;
              "profile.d/xdg_dirs_extra.sh".source = ./etc/profile.d/xdg_dirs_extra.sh;
              "sysctl.d/60-apparmor-namespace.conf".source = ./etc/sysctl.d/60-apparmor-namespace.conf;
            };
            rog2 =
              if config.setup.hostname != "rog2" then
                { }
              else
                {
                  "udev/rules.d/60-openrgb.rules".source =
                    "${pkgs.openrgb-with-all-plugins}/lib/udev/rules.d/60-openrgb.rules";
                  "sudoers.d/keepterminfo".text = ''
                    Defaults:${username} env_keep += "TERMINFO TERMINFO_DIRS"
                  '';
                  "sudoers.d/nix_sm_paths".text = ''
                    Defaults:${username} secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/run/wrappers/bin:/run/system-manager/sw/bin/"
                  '';
                  # todo: keep this here until liquidctl is updated to run with my water cooler
                  "udev/rules.d/71-liquidctl.rules".source = "${pkgs.liquidctl}/lib/udev/rules.d/71-liquidctl.rules";
                  "udev/rules.d/80-video.rules".source = ./etc/udev/rules.d/80-video.rules;
                  "apparmor.d/usr.local.bin.liquidctl".source = ./etc/apparmor.d/usr.local.bin.liquidctl;
                  "sensors.d/disabling".source = ./etc/sensors.d/disabling;
                  "systemd/timesyncd.conf.d/local_network.conf".source =
                    ./etc/systemd/timesyncd.conf.d/local_network.conf; # Ubuntu is not picking up DHCP configuration for NTP (option 42)
                  "sysctl.d/70-ping_group_range.conf".source = ./etc/sysctl.d/70-ping_group_range.conf;
                };
          in
          builtins.mapAttrs (n: v: v // { replaceExisting = true; }) (all // rog2);
      };

      systemd = {
        services =
          let
            all = {
              # todo: Use activation scripts when ready? See: https://github.com/numtide/system-manager/issues/221
              system-manager-activate = {
                description = "System-manager activation scripts";
                enable = true;
                wantedBy = [ "system-manager.target" ];
                serviceConfig = {
                  Type = "oneshot";
                  RemainAfterExit = true;
                };
                script =
                  let
                    all = ''
                      echo "Reloading apparmor rules..."
                      ${lib.getBin pkgs.apparmor-parser}/bin/apparmor_parser -r /etc/apparmor.d/usr.local.bin.liquidctl
                      echo "Reloading sysctl config..."
                      ${lib.getBin pkgs.sysctl}/bin/sysctl --system
                    '';
                    wsl = if config.setup.wsl then "" else "";
                    rog2 =
                      if config.setup.hostname != "rog2" then
                        ""
                      else
                        ''
                          echo "Reloading udev rules..."
                          udevadm control --reload
                          echo "Triggering udev rules..."
                          udevadm trigger
                        '';
                  in
                  all + wsl + rog2;
              };
            };
            wsl =
              if config.setup.wsl then
                {
                  wsl-add-winhost = {
                    # todo: probably will fail inside container, fix it
                    description = "Set winhost in /etc/hosts";
                    serviceConfig = {
                      ExecStart = ./bin/wsl-add-winhost;
                      RemainAfterExit = true;
                      Type = "oneshot";
                    };
                    wantedBy = [ "multi-user.target" ];
                    path = with pkgs; [
                      bash
                      coreutils
                      gnugrep
                      gnused
                      gawk
                    ];
                  };
                  wsl-clean-memory = {
                    description = "Clean WSL Memory if needed";
                    serviceConfig = {
                      ExecStart = ./bin/wsl-clean-memory;
                    };
                    path = with pkgs; [
                      bash
                      coreutils
                      gawk
                    ];
                  };
                }
              else
                { };
            rog2 =
              if config.setup.hostname != "rog2" then
                { }
              else
                {
                  coolercontrol-restart = {
                    description = "Restart coolercontrol services";
                    enable = true;
                    wantedBy = [
                      "suspend.target"
                      "hibernate.target"
                      "hybrid-sleep.target"
                      "suspend-then-hibernate.target"
                    ];
                    after = [
                      "suspend.target"
                      "hibernate.target"
                      "hybrid-sleep.target"
                      "suspend-then-hibernate.target"
                    ];
                    serviceConfig = {
                      Type = "oneshot";
                      ExecStart = "/usr/bin/sh -c 'if systemctl list-units --type=service | grep coolercontrold.service &> /dev/null; then /usr/bin/systemctl restart coolercontrold.service; fi'";
                    };
                  };
                };
          in
          all // rog2 // wsl;

        timers =
          let
            all = { };
            wsl =
              if config.setup.wsl then
                {
                  wsl-clean-memory = {
                    description = "Clean WSL Memory if needed on a timer";
                    timerConfig = {
                      OnCalendar = "*-*-* 0:0/5:00";
                      Unit = "wsl-clean-memory.service";
                    };
                    wantedBy = [ "multi-user.target" ];
                  };
                }
              else
                { };
          in
          all // wsl;

        units =
          let
            wsl = if config.setup.wsl then { } else { };
            rog2 =
              if config.setup.hostname != "rog2" then
                { }
              else
                {
                  "coolercontrold.service" = {
                    enable = true;
                    wantedBy = [ "system-manager.target" ];
                    text = builtins.readFile "${pkgs.coolercontrol.coolercontrold}/lib/systemd/system/coolercontrold.service";
                  };
                };
          in
          rog2 // wsl;
        # Configure systemd tmpfile settings
        tmpfiles = {
          # rules = [
          #   "D /var/tmp/system-manager 0755 root root -"
          # ];
          #
          # settings.sample = {
          #   "/var/tmp/sample".d = {
          #     mode = "0755";
          #   };
          # };
        };
      };
      security = {
        enableWrappers = true;
        wrappers = {
          ping = {
            owner = "root";
            group = "root";
            capabilities = "cap_net_raw+ep";
            source = "${pkgs.inetutils}/bin/ping";
          };
        };
      };
    };
}
