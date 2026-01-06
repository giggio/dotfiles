{
  callPackage,
  symlinkJoin,
  dotnet-sdk,
  dotnet-runtime,
}:

symlinkJoin {
  name = "dotnet-tools";
  paths = [
    (callPackage ./dotnet-counters.nix {
      inherit dotnet-sdk;
      inherit dotnet-runtime;
    })
    (callPackage ./dotnet-dump.nix {
      inherit dotnet-sdk;
      inherit dotnet-runtime;
    })
    (callPackage ./dotnet-trace.nix {
      inherit dotnet-sdk;
      inherit dotnet-runtime;
    })
    (callPackage ./dotnet-sos.nix {
      inherit dotnet-sdk;
      inherit dotnet-runtime;
    })
    (callPackage ./dotnet-symbol.nix {
      inherit dotnet-sdk;
      inherit dotnet-runtime;
    })
    (callPackage ./dotnet-gcdump.nix {
      inherit dotnet-sdk;
      inherit dotnet-runtime;
    })
    (callPackage ./dotnet-interactive.nix {
      inherit dotnet-sdk;
      inherit dotnet-runtime;
    })
    (callPackage ./dotnet-aspnet-codegenerator.nix {
      inherit dotnet-sdk;
      inherit dotnet-runtime;
    })
    (callPackage ./dotnet-script.nix {
      inherit dotnet-sdk;
      inherit dotnet-runtime;
    })
    (callPackage ./dotnet-delice.nix {
      inherit dotnet-sdk;
      inherit dotnet-runtime;
    })
    (callPackage ./git-istage.nix {
      inherit dotnet-sdk;
      inherit dotnet-runtime;
    })
    (callPackage ./httprepl.nix {
      inherit dotnet-sdk;
      inherit dotnet-runtime;
    })
  ];
  meta.priority = 10;
}
