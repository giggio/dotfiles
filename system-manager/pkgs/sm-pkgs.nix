inputs: self: super:
let
  pkgs = super;
in
with pkgs;
{
  sm = writeShellApplication {
    name = "sm";
    runtimeInputs = [
      gnugrep
      inputs.system-manager.packages.${stdenv.hostPlatform.system}.default # system-manager binary
    ];
    text = builtins.readFile ../bin/sm;
  };
}
