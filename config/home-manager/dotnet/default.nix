# used for testing with `nix-build -A dotnet-tools`
let
  pkgs = import <nixpkgs> {};
  dotnet-sdk = (with pkgs.dotnetCorePackages; combinePackages
    [
      sdk_6_0
      sdk_7_0
      sdk_8_0
    ]);
in
{
  dotnet-tools = import ./dotnet-tools.nix { inherit pkgs; inherit dotnet-sdk; };
}
