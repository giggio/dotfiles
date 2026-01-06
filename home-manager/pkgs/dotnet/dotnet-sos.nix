{
  lib,
  buildDotnetGlobalTool,
  dotnet-sdk,
  dotnet-runtime,
}:

buildDotnetGlobalTool {
  pname = "dotnet-sos";
  version = "9.0.553101";

  nugetSha256 = "sha256-haDr9uXVw4RksPqsA8/iwoRJqx5Lcm+ioBaPP5Wooc4=";
  dotnet-sdk = dotnet-sdk;
  dotnet-runtime = dotnet-runtime;

  meta = with lib; {
    homepage = "https://github.com/dotnet/diagnostics";
    changelog = "https://github.com/dotnet/diagnostics/releases";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
