pkgs:
let
  dotnet-sdk =
    with pkgs.dotnetCorePackages;
    combinePackages [
      sdk_10_0
    ];
in
{
  dotnet-runtime = dotnet-sdk;
  dotnet = pkgs.buildEnv {
    name = "mypkgs";
    paths = [
      dotnet-sdk # .NET SDK https://dot.net
      (pkgs.callPackage ./dotnet-tools.nix { }) # Collection of useful command-line tools for .NET
      (pkgs.callPackage ./dotnet-install.nix { }) # .NET SDK installer script https://dot.net
    ];
  };
}
