{
  description = "Home Manager configuration of giggio";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
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
      mkHomeManagerConfiguration =
        {
          extraModule ? { },
          extraSpecialArgs ? { },
          ...
        }:
        home-manager.lib.homeManagerConfiguration ({
          inherit pkgs;

          modules = [
            ./options.nix
            extraModule
            ./home.nix
          ];

          extraSpecialArgs = {
            inherit inputs;
            pkgs-stable = inputs.nixpkgs-stable.legacyPackages.${system};
          }
          // extraSpecialArgs;
        });
    in
    {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-tree;
      homeConfigurations =
        let
          wslSetup = {
            setup.wsl = true;
          };
          nixosSetup = {
            setup.isNixOS = true;
          };
          basicSetup = {
            setup.basicSetup = true;
          };
          virtualboxSetup = {
            setup.isVirtualBox = true;
          };
        in
        {
          # available profiles: giggio, giggio_wsl, giggio_virtualbox_nixos, giggio_nixos, giggio_basic, giggio_wsl_basic, giggio_virtualbox_basic, giggio_virtualbox_nixos_basic, giggio_nixos_basic
          giggio = mkHomeManagerConfiguration { };
          giggio_wsl = mkHomeManagerConfiguration { extraModule = wslSetup; };
          giggio_virtualbox_nixos = mkHomeManagerConfiguration { extraModule = virtualboxSetup; };
          giggio_nixos = mkHomeManagerConfiguration { extraModule = nixosSetup // nixosSetup; };
          giggio_basic = mkHomeManagerConfiguration { extraModule = basicSetup; };
          giggio_wsl_basic = mkHomeManagerConfiguration { extraModule = wslSetup // basicSetup; };
          giggio_virtualbox_basic = mkHomeManagerConfiguration {
            extraModule = virtualboxSetup // basicSetup;
          };
          giggio_virtualbox_nixos_basic = mkHomeManagerConfiguration {
            extraModule = virtualboxSetup // nixosSetup // basicSetup;
          };
          giggio_nixos_basic = mkHomeManagerConfiguration { extraModule = nixosSetup // basicSetup; };
        };
      devShells = {
        ${system}.default = pkgs.mkShell {
          name = "Image build environment";
          buildInputs = with pkgs; [
            sops
          ];
          shellHook = ''
            echo "Welcome to dotfiles!"
          '';
        };
      };
    };
}
