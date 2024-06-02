{ pkgs, dotnet-sdk, ... }:

pkgs.buildDotnetGlobalTool {
  pname = "dotnet-symbol";
  version = "1.0.415602";

  nugetSha256 = "sha256-sD4xkRwBYo8nzMXI6xBya2i8MDJNgCu57Y8A8MuAgvI=";
  dotnet-sdk = dotnet-sdk;

  meta = with pkgs.lib; {
    homepage = "https://github.com/dotnet/symstore";
    changelog = "https://github.com/dotnet/symstore/releases";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
