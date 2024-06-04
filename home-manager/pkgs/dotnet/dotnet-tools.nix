{ callPackage, symlinkJoin, dotnet-sdk }:

symlinkJoin {
  name = "dotnet-tools";
  paths = [
    (callPackage ./dotnet-counters.nix { inherit dotnet-sdk; })
    (callPackage ./dotnet-dump.nix { inherit dotnet-sdk; })
    (callPackage ./dotnet-trace.nix { inherit dotnet-sdk; })
    (callPackage ./dotnet-sos.nix { inherit dotnet-sdk; })
    (callPackage ./dotnet-symbol.nix { inherit dotnet-sdk; })
    (callPackage ./dotnet-gcdump.nix { inherit dotnet-sdk; })
    (callPackage ./dotnet-interactive.nix { inherit dotnet-sdk; })
    (callPackage ./dotnet-aspnet-codegenerator.nix { inherit dotnet-sdk; })
    (callPackage ./dotnet-script.nix { inherit dotnet-sdk; })
    (callPackage ./dotnet-delice.nix { inherit dotnet-sdk; })
    (callPackage ./git-istage.nix { inherit dotnet-sdk; })
    (callPackage ./httprepl.nix { inherit dotnet-sdk; })
  ];
  meta.priority = 10;
}
