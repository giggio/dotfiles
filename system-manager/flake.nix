{
  description = "Standalone System Manager configuration";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    system-manager = {
      url = "github:numtide/system-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, system-manager, ... }@inputs:
    let
      system = "x86_64-linux";
      mkSystemManagerConfiguration = { extraSpecialArgs, ... }: system-manager.lib.makeSystemConfig ({
        modules = [
          ./configuration.nix
          ./system.nix
        ];
        extraSpecialArgs = {
          inherit inputs;
          inherit system;
          pkgs-stable = inputs.nixpkgs-stable.legacyPackages.${system};
        } // extraSpecialArgs;
        # Optionally specify overlays
      });
    in
    {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
      systemConfigs =
        let
          setup = {
            wsl = false;
            basicSetup = false;
            isVirtualBox = false;
            hostname = "";
          };
        in
        {
          # available profiles: default, rog2, giggio, giggio_wsl, giggio_virtualbox, giggio_basic, giggio_wsl_basic, giggio_virtualbox_basic
          default = mkSystemManagerConfiguration {
            extraSpecialArgs = { inherit setup; };
          };
          x86_64-linux = {
            rog2 = mkSystemManagerConfiguration {
              # machine specific
              extraSpecialArgs = { setup = setup // { hostname = "rog2"; }; };
            };
            giggio = mkSystemManagerConfiguration {
              extraSpecialArgs = { inherit setup; };
            };
            giggio_wsl = mkSystemManagerConfiguration {
              extraSpecialArgs = {
                setup = setup // { wsl = true; };
              };
            };
            giggio_virtualbox = mkSystemManagerConfiguration {
              extraSpecialArgs = {
                setup = setup // { isVirtualBox = true; isNixOS = true; };
              };
            };
            giggio_basic = mkSystemManagerConfiguration {
              extraSpecialArgs = {
                setup = setup // { basicSetup = true; };
              };
            };
            giggio_wsl_basic = mkSystemManagerConfiguration {
              extraSpecialArgs = {
                setup = setup // { wsl = true; basicSetup = true; };
              };
            };
            giggio_virtualbox_basic = mkSystemManagerConfiguration {
              extraSpecialArgs = {
                setup = setup // { isVirtualBox = true; basicSetup = true; };
              };
            };
          };
        };
    };
}
