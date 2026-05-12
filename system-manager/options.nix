{ lib, ... }:
with lib;
{
  options.setup = {
    wsl = mkEnableOption "WSL enabled";
    basicSetup = mkEnableOption "Basic setup enabled";
    isVirtualBox = mkEnableOption "VirtualBox enabled";
    hostname = mkOption {
      type = types.str;
      example = literalExpression "abc";
      description = "Machine hostname";
    };
  };
}
