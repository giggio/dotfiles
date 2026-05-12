{ lib, ... }:
with lib;
{
  options.setup = {
    wsl = mkEnableOption "WSL enabled";
    basicSetup = mkEnableOption "Basic setup enabled";
    isNixOS = mkEnableOption "NixOS enabled";
    isVirtualBox = mkEnableOption "VirtualBox enabled";
    homeManagerRelativeConfigPath = mkOption {
      type = types.str;
      default = ".dotfiles/home-manager";
      example = literalExpression ".dotfiles/home-manager";
      description = "Home Manager relative to home config path";
    };
  };
}
