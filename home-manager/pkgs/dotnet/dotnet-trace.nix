{ lib, buildDotnetGlobalTool, dotnet-sdk, dotnet-runtime }:

buildDotnetGlobalTool {
  pname = "dotnet-trace";
  version = "9.0.553101";

  nugetSha256 = "sha256-8/jEdLlSL682lZQHlseZLM2Sd1FmlhZT+YbNjBsiEDo=";
  dotnet-sdk = dotnet-sdk;
  dotnet-runtime = dotnet-runtime;

  meta = with lib; {
    homepage = "https://github.com/dotnet/diagnostics";
    changelog = "https://github.com/dotnet/diagnostics/releases";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
