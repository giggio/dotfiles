{ lib, buildDotnetGlobalTool, dotnet-sdk, dotnet-runtime }:

buildDotnetGlobalTool {
  pname = "dotnet-delice";
  version = "2.0.0";

  nugetSha256 = "sha256-e6ATl06VwvgK2cVzDMO272OIBLpm/+ed6Ba+kd3rHzQ=";
  dotnet-sdk = dotnet-sdk;
  dotnet-runtime = dotnet-runtime;

  meta = with lib; {
    homepage = "https://github.com/aaronpowell/dotnet-delice";
    changelog = "https://github.com/aaronpowell/dotnet-delice/blob/main/CHANGELOG.md";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
