{ pkgs, dotnet-sdk }:

pkgs.symlinkJoin {
  name = "dotnet-tools";
  paths = [
    (import ./dotnet-counters.nix { inherit pkgs; inherit dotnet-sdk; })
    (import ./dotnet-dump.nix { inherit pkgs; inherit dotnet-sdk; })
    (import ./dotnet-trace.nix { inherit pkgs; inherit dotnet-sdk; })
    (import ./dotnet-sos.nix { inherit pkgs; inherit dotnet-sdk; })
    (import ./dotnet-symbol.nix { inherit pkgs; inherit dotnet-sdk; })
    (import ./dotnet-gcdump.nix { inherit pkgs; inherit dotnet-sdk; })
    (import ./dotnet-interactive.nix { inherit pkgs; inherit dotnet-sdk; })
    (import ./dotnet-aspnet-codegenerator.nix { inherit pkgs; inherit dotnet-sdk; })
    (import ./dotnet-script.nix { inherit pkgs; inherit dotnet-sdk; })
    (import ./dotnet-delice.nix { inherit pkgs; inherit dotnet-sdk; })
    (import ./git-istage.nix { inherit pkgs; inherit dotnet-sdk; })
    (import ./httprepl.nix { inherit pkgs; inherit dotnet-sdk; })
  ];
  meta.priority = 10;
}
