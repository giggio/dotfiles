{
  description = "Standalone System Manager configuration";
  inputs = {
    # nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    system-manager = {
      url = "github:numtide/system-manager?ref=v1.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      system-manager,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      mkSystemManagerConfiguration =
        {
          extraModule ? { },
          specialArgs ? { },
        }:
        system-manager.lib.makeSystemConfig ({
          modules = [
            ./options.nix
            extraModule
            ./configuration.nix
            ./system.nix
          ];
          extraSpecialArgs = {
            inherit inputs;
            inherit system;
            pkgs-stable = inputs.nixpkgs-stable.legacyPackages.${system};
          }
          // specialArgs;
        });
    in
    {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-tree;
      systemConfigs =
        let
          wslSetup = {
            setup.wsl = true;
          };
          basicSetup = {
            setup.basicSetup = true;
          };
          virtualboxSetup = {
            setup.isVirtualBox = true;
          };
        in
        {
          # available profiles: default, rog2, giggio, giggio_wsl, giggio_virtualbox, giggio_basic, giggio_wsl_basic, giggio_virtualbox_basic
          default = mkSystemManagerConfiguration { };
          x86_64-linux = {
            rog2 = mkSystemManagerConfiguration {
              # machine specific
              extraModule = {
                setup.hostname = "rog2";
              };
            };
            giggio-sp5 = mkSystemManagerConfiguration {
              # machine specific
              extraModule = wslSetup // {
                setup.hostname = "giggio-sp5";
              };
            };
            giggio = mkSystemManagerConfiguration { };
            giggio_wsl = mkSystemManagerConfiguration { extraModule = wslSetup; };
            giggio_virtualbox = mkSystemManagerConfiguration { extraModule = virtualboxSetup; };
            giggio_basic = mkSystemManagerConfiguration { extraModule = basicSetup; };
            giggio_wsl_basic = mkSystemManagerConfiguration { extraModule = wslSetup // basicSetup; };
            giggio_virtualbox_basic = mkSystemManagerConfiguration {
              extraModule = virtualboxSetup // basicSetup;
            };
          };
        };
    };
}
