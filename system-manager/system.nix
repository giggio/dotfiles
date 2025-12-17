{ lib, pkgs, setup, ... }:
{
  config = {
    nixpkgs.hostPlatform = "x86_64-linux";

    services = { };

    environment = {
      systemPackages = with pkgs; [
        gnupg # todo: remove, testing only
      ];

      # Add directories and files to `/etc` and set their permissions
      etc = {
        "systemd/logind.conf".source = ./etc/systemd/logind.conf;
        # with_ownership = {
        #   text = ''
        #     This is just a test!
        #   '';
        #   mode = "0755";
        #   uid = 5;
        #   gid = 6;
        # };
      };
    };

    systemd = {
      services = let
        wsl = if setup.wsl then { } else { };
        rog2 = if setup.hostname != "rog2" then { } else {
          coolercontrol-restart = {
            description = "Restart coolercontrol services";
            enable = true;
            wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" "suspend-then-hibernate.target" ];
            after = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" "suspend-then-hibernate.target" ];
            serviceConfig = {
              Type = "oneshot";
              ExecStart= "/usr/bin/sh -c 'if systemctl list-units --type=service | grep coolercontrold.service &> /dev/null; then /usr/bin/systemctl restart coolercontrol-liqctld.service coolercontrold.service; fi'";
            };
          };
        };
      in rog2 // wsl;
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
