{ pkgs, dotnet-sdk, ... }:

pkgs.buildDotnetGlobalTool {
  pname = "dotnet-gcdump";
  version = "8.0.510501";

  nugetSha256 = "sha256-y10InQA1sAvFYrRe+7I2+txKOvu1qQ1ii/7DnXvipxM=";
  dotnet-sdk = dotnet-sdk;

  meta = with pkgs.lib; {
    homepage = "https://github.com/dotnet/diagnostics";
    changelog = "https://github.com/dotnet/diagnostics/releases";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
