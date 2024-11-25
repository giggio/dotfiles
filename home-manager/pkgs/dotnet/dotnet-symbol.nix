{ lib, buildDotnetGlobalTool, dotnet-sdk, dotnet-runtime }:

buildDotnetGlobalTool {
  pname = "dotnet-symbol";
  version = "9.0.553101";

  nugetSha256 = "sha256-/pFODZt0azL+d1GyTz9BOyQ09ORAHU7LdFM7Rxg1ZFE=";
  dotnet-sdk = dotnet-sdk;
  dotnet-runtime = dotnet-runtime;

  meta = with lib; {
    homepage = "https://github.com/dotnet/symstore";
    changelog = "https://github.com/dotnet/symstore/releases";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
