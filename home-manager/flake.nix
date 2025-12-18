{
  description = "Home Manager configuration of giggio";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      mkHomeManagerConfiguration = { extraSpecialArgs, ... }: home-manager.lib.homeManagerConfiguration ({
        inherit pkgs;

        modules = [ ./home.nix ];

        extraSpecialArgs = {
          inherit inputs;
          pkgs-stable = inputs.nixpkgs-stable.legacyPackages.${system};
        } // extraSpecialArgs;
      });
    in
    {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
      homeConfigurations =
        let
          setup = {
            wsl = false;
            basicSetup = false;
            isNixOS = false;
            isVirtualBox = false;
          };
        in
        {
          # available profiles: giggio, giggio_wsl, giggio_virtualbox_nixos, giggio_nixos, giggio_basic, giggio_wsl_basic, giggio_virtualbox_basic, giggio_virtualbox_nixos_basic, giggio_nixos_basic
          giggio = mkHomeManagerConfiguration {
            extraSpecialArgs = { inherit setup; };
          };
          giggio_wsl = mkHomeManagerConfiguration {
            extraSpecialArgs = {
              setup = setup // { wsl = true; };
            };
          };
          giggio_virtualbox_nixos = mkHomeManagerConfiguration {
            extraSpecialArgs = {
              setup = setup // { isVirtualBox = true; isNixOS = true; };
            };
          };
          giggio_nixos = mkHomeManagerConfiguration {
            extraSpecialArgs = {
              setup = setup // { isNixOS = true; };
            };
          };
          giggio_basic = mkHomeManagerConfiguration {
            extraSpecialArgs = {
              setup = setup // { basicSetup = true; };
            };
          };
          giggio_wsl_basic = mkHomeManagerConfiguration {
            extraSpecialArgs = {
              setup = setup // { wsl = true; basicSetup = true; };
            };
          };
          giggio_virtualbox_basic = mkHomeManagerConfiguration {
            extraSpecialArgs = {
              setup = setup // { isVirtualBox = true; basicSetup = true; };
            };
          };
          giggio_virtualbox_nixos_basic = mkHomeManagerConfiguration {
            extraSpecialArgs = {
              setup = setup // { isVirtualBox = true; isNixOS = true; basicSetup = true; };
            };
          };
          giggio_nixos_basic = mkHomeManagerConfiguration {
            extraSpecialArgs = {
              setup = setup // { isNixOS = true; basicSetup = true; };
            };
          };
        };
    };
}
