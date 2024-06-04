{ pkgs, dotnet-sdk, ... }:

pkgs.buildDotnetGlobalTool {
  pname = "dotnet-interactive";
  nugetName = "Microsoft.dotnet-interactive";
  version = "1.0.522904";

  nugetSha256 = "sha256-ULnG2D7BUJV39cSC4sarWlrngtv492vpd/BjeB5dKYQ=";
  dotnet-sdk = dotnet-sdk;

  meta = with pkgs.lib; {
    homepage = "https://github.com/dotnet/interactive";
    changelog = "https://github.com/dotnet/interactive/releases";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
