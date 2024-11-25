{ lib, buildDotnetGlobalTool, dotnet-sdk, dotnet-runtime }:

buildDotnetGlobalTool {
  pname = "dotnet-aspnet-codegenerator";
  version = "9.0.0";

  nugetSha256 = "sha256-BTOpf51sLXNQEobzRIsiCsVIBCIhLeyDeZrMJqiMp4c=";
  dotnet-sdk = dotnet-sdk;
  dotnet-runtime = dotnet-runtime;

  meta = with lib; {
    homepage = "https://github.com/dotnet/Scaffolding";
    changelog = "https://github.com/dotnet/Scaffolding/releases";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
