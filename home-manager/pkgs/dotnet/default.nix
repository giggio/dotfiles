# used for testing with `nix-build -A dotnet-tools`
let
  pkgs = import <nixpkgs> { };
  dotnet-sdk = pkgs.dotnetCorePackages.sdk_9_0;
  dotnet-runtime = pkgs.dotnetCorePackages.sdk_9_0;
in
{
  dotnet-tools = pkgs.callPackage ./dotnet-tools.nix {
    inherit dotnet-sdk;
    inherit dotnet-runtime;
  };
}
