{
  lib,
  buildDotnetGlobalTool,
  dotnet-sdk,
  dotnet-runtime,
}:

buildDotnetGlobalTool {
  pname = "dotnet-gcdump";
  version = "9.0.553101";

  nugetSha256 = "sha256-pTtil4Rzg6GpFUu297YNXJAdoaSN+BetjKH2Ke0gyjs=";
  dotnet-sdk = dotnet-sdk;
  dotnet-runtime = dotnet-runtime;

  meta = with lib; {
    homepage = "https://github.com/dotnet/diagnostics";
    changelog = "https://github.com/dotnet/diagnostics/releases";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
