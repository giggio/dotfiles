{ pkgs, lib, callPackage }:

let
  callPackage = lib.callPackageWith (pkgs // our_packages);
  our_packages = {
    inherit callPackage;
    dotnet-sdk = with pkgs.dotnetCorePackages; combinePackages
      [
        sdk_6_0
        sdk_7_0
        sdk_8_0
      ];
    dotnet-tools = callPackage ./dotnet/dotnet-tools.nix { };
    dotnet-install = callPackage ./dotnet/dotnet-install.nix { };
    nodejs = pkgs.nodePackages_latest.nodejs;
    extra-completions = callPackage ./completions.nix { };
    terraform = callPackage ./unfree/terraform.nix { };
    vault = callPackage ./unfree/vault.nix { };
    rust = pkgs.fenix.stable.withComponents [ "cargo" "clippy" "rust-src" "rustc" "rustfmt" ];
    cargo-completions = callPackage ./rust/cargo-completions.nix { };
    loadtest = callPackage ./nodejs/loadtest.nix { };
    prettier-plugin-awk = callPackage ./nodejs/prettier-plugin-awk.nix { };
    chart-releaser = callPackage ./golang/chart-releaser.nix { };
    docker-show-context = callPackage ./golang/docker-show-context.nix { };
    kubectl-aliases = callPackage ./aliases/kubectl-aliases.nix { };
  };
  all_packages = pkgs // our_packages;
in
all_packages
