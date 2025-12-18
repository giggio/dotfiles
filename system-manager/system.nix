{ lib, pkgs, setup, system, inputs, ... }:
{
  config =
    let
      system-manager = inputs.system-manager;
    in
    {
      nixpkgs.hostPlatform = "x86_64-linux";

      services = { };

      environment = {
        systemPackages =
          let
            all = (with pkgs; [
              system-manager.packages.${system}.default # system-manager binary
            ]);
            rog2 = lib.lists.optionals (setup.hostname == "rog2") (with pkgs; [
              lm_sensors # Tools for reading hardware sensors - maintained fork https://github.com/hramrach/lm-sensors https://archive.kernel.org/oldwiki/hwmon.wiki.kernel.org/lm_sensors.html
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
            };
            rog2 = if setup.hostname != "rog2" then { } else {
              # todo: keep this here until liquidctl is updated to run with my water cooler
              # todo: needs to run after: "udevadm control --reload; udevadm trigger", see: https://github.com/numtide/system-manager/issues/221
              "udev/rules.d/71-liquidctl.rules".source = "${pkgs.liquidctl}/lib/udev/rules.d/71-liquidctl.rules";
              # todo: needs to run after: apparmor_parser -r /etc/apparmor.d/usr.local.bin.liquidctl, see: https://github.com/numtide/system-manager/issues/221
              "apparmor.d/usr.local.bin.liquidctl".source = ./etc/apparmor.d/usr.local.bin.liquidctl;
              "sensors.d/disabling".source = ./etc/sensors.d/disabling;
            };
          in
          all // rog2;
      };

      systemd = {
        services =
          let
            wsl = if setup.wsl then { } else { };
            rog2 = if setup.hostname != "rog2" then { } else {
              coolercontrol-restart = {
                description = "Restart coolercontrol services";
                enable = true;
                wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" "suspend-then-hibernate.target" ];
                after = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" "suspend-then-hibernate.target" ];
                serviceConfig = {
                  Type = "oneshot";
                  ExecStart = "/usr/bin/sh -c 'if systemctl list-units --type=service | grep coolercontrold.service &> /dev/null; then /usr/bin/systemctl restart coolercontrol-liqctld.service coolercontrold.service; fi'";
                };
              };
            };
          in
          rog2 // wsl;
        units =
          let
            wsl = if setup.wsl then { } else { };
            rog2 = if setup.hostname != "rog2" then { } else {
              "coolercontrold.service" = {
                # todo: because of a bug it is not being enabled, needs to run `systemctl enable coolercontrold`, see: https://github.com/numtide/system-manager/issues/298
                enable = true;
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

    };
}
