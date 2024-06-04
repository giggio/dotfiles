{ lib, buildDotnetGlobalTool , dotnet-sdk }:

buildDotnetGlobalTool {
  pname = "dotnet-sos";
  version = "8.0.510501";

  nugetSha256 = "sha256-IwWqYPq8YW9ZwsQHe6ZTdR2N/UgLvV4snQ5gW4HsJ9Y=";
  dotnet-sdk = dotnet-sdk;

  meta = with lib; {
    homepage = "https://github.com/dotnet/diagnostics";
    changelog = "https://github.com/dotnet/diagnostics/releases";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
