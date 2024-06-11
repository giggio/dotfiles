{ pkgs }:

with pkgs;
{
  dotnet-sdk = with dotnetCorePackages; combinePackages
    [
      sdk_6_0
      sdk_7_0
      sdk_8_0
    ];
  dotnet-tools = callPackage ./dotnet/dotnet-tools.nix { };
  dotnet-install = callPackage ./dotnet/dotnet-install.nix { };
  extra-completions = callPackage ./completions.nix { };
  terraform = callPackage ./unfree/terraform.nix { };
  vault = callPackage ./unfree/vault.nix { };
  rust-toolchain = fenix.stable.withComponents [ "cargo" "clippy" "rust-src" "rustc" "rustfmt" ];
  cargo-completions = callPackage ./rust/cargo-completions.nix { };
  loadtest = callPackage ./nodejs/loadtest.nix { };
  prettier-plugin-awk = callPackage ./nodejs/prettier-plugin-awk.nix { };
  chart-releaser = callPackage ./golang/chart-releaser.nix { };
  docker-show-context = callPackage ./golang/docker-show-context.nix { };
  kubectl-aliases = callPackage ./aliases/kubectl-aliases.nix { };
  microsoft-edge-pipewire = callPackage ./ms-edge.nix { };
}
