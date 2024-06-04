{ lib, buildDotnetGlobalTool , dotnet-sdk }:

buildDotnetGlobalTool {
  pname = "httprepl";
  nugetName = "Microsoft.dotnet-httprepl";
  version = "7.0.0";

  nugetSha256 = "sha256-optL8O7C9jGOZaRdltZciqtCQOF4GhFtrNQ3FKa8qbE=";
  dotnet-sdk = dotnet-sdk;

  meta = with lib; {
    homepage = "https://github.com/dotnet/HttpRepl";
    changelog = "https://github.com/dotnet/HttpRepl/releases";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
