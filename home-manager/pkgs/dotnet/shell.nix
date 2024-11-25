# used for testing with `nix-shell`
{ pkgs ? import <nixpkgs> { } }:
let
  dotnet-sdk = (with pkgs.dotnetCorePackages; combinePackages
    [
      sdk_8_0
      sdk_9_0
    ]);
  dotnet-runtime = pkgs.dotnetCorePackages.sdk_9_0;
in
pkgs.mkShell {
  nativeBuildInputs = [ (import ./dotnet-tools.nix { callPackage = pkgs.callPackage; symlinkJoin = pkgs.symlinkJoin; inherit dotnet-sdk; inherit dotnet-runtime; }) ];
}
