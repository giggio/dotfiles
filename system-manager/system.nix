{
  lib,
  pkgs,
  setup,
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
          let
            all = ([
              system-manager.packages.${system}.default # system-manager binary
            ]);
            rog2 = lib.lists.optionals (setup.hostname == "rog2") (
              with pkgs;
              [
                lm_sensors # Tools for reading hardware sensors - maintained fork https://github.com/hramrach/lm-sensors https://archive.kernel.org/oldwiki/hwmon.wiki.kernel.org/lm_sensors.html
                liquidctl # Cross-platform CLI and Python drivers for AIO liquid coolers and other devices https://github.com/liquidctl/liquidctl
                coolercontrol.coolercontrold # Monitor and control your cooling devices (Main Daemon) https://gitlab.com/coolercontrol/coolercontrol
              ]
            );
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
              if setup.hostname != "rog2" then
                { }
              else
                {
                  "udev/rules.d/60-openrgb.rules".source =
                    "${pkgs.openrgb-with-all-plugins}/lib/udev/rules.d/60-openrgb.rules";
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
          all // rog2;
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
                    wsl = if setup.wsl then "" else "";
                    rog2 =
                      if setup.hostname != "rog2" then
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
              if setup.wsl then
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
              if setup.hostname != "rog2" then
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
                      ExecStart = "/usr/bin/sh -c 'if systemctl list-units --type=service | grep coolercontrold.service &> /dev/null; then /usr/bin/systemctl restart coolercontrol-liqctld.service coolercontrold.service; fi'";
                    };
                  };
                };
          in
          all // rog2 // wsl;

        timers =
          let
            all = { };
            wsl =
              if setup.wsl then
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
            wsl = if setup.wsl then { } else { };
            rog2 =
              if setup.hostname != "rog2" then
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
