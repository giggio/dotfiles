{ lib, ... }:
{
  options.setup = {
    user = lib.mkOption {
      type = lib.types.str;
      default = "giggio";
    };
    wsl = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    basicSetup = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    isNixOS = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };
}
