# used for testing with `nix-shell`
{ pkgs ? import <nixpkgs> {} }:
let
  dotnet-sdk = (with pkgs.dotnetCorePackages; combinePackages
    [
      sdk_6_0
      sdk_7_0
      sdk_8_0
    ]);
in
pkgs.mkShell {
  nativeBuildInputs = [ (import ./dotnet-tools.nix { inherit pkgs; inherit dotnet-sdk; }) ];
}
