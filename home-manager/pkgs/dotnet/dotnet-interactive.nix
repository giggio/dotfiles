{
  lib,
  buildDotnetGlobalTool,
  dotnet-sdk,
  dotnet-runtime,
}:

buildDotnetGlobalTool {
  pname = "dotnet-interactive";
  nugetName = "Microsoft.dotnet-interactive";
  version = "1.0.556801";

  nugetSha256 = "sha256-tABt/DltggX85SZaaZK7ZP+L3EqxEh0fZ1pfB4MOtxk=";
  dotnet-sdk = dotnet-sdk;
  dotnet-runtime = dotnet-runtime;

  meta = with lib; {
    homepage = "https://github.com/dotnet/interactive";
    changelog = "https://github.com/dotnet/interactive/releases";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
