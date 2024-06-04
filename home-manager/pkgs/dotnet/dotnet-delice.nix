{ lib, buildDotnetGlobalTool , dotnet-sdk }:

buildDotnetGlobalTool {
  pname = "dotnet-delice";
  version = "1.8.0";

  nugetSha256 = "sha256-aGqpZAltnsMg1OuqOmN+mvw/zPwW6sZZUx2YKVJe2Eo=";
  dotnet-sdk = dotnet-sdk;

  meta = with lib; {
    homepage = "https://github.com/aaronpowell/dotnet-delice";
    changelog = "https://github.com/aaronpowell/dotnet-delice/blob/main/CHANGELOG.md";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
