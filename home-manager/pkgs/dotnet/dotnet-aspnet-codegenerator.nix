{ lib, buildDotnetGlobalTool, dotnet-sdk }:

buildDotnetGlobalTool {
  pname = "dotnet-aspnet-codegenerator";
  version = "8.0.2";

  nugetSha256 = "sha256-NGoEPq+hh742Lahd5RazQ87nVDVT9rHIMu6X4LhIV1A=";
  dotnet-sdk = dotnet-sdk;

  meta = with lib; {
    homepage = "https://github.com/dotnet/Scaffolding";
    changelog = "https://github.com/dotnet/Scaffolding/releases";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
