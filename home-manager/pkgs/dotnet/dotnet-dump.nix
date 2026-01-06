{
  lib,
  buildDotnetGlobalTool,
  dotnet-sdk,
  dotnet-runtime,
}:

buildDotnetGlobalTool {
  pname = "dotnet-dump";
  version = "9.0.553101";

  nugetSha256 = "sha256-K2Q/HON6nk8yvVZxn5UuTpXEQcrS0QukPkfAukwUxJs=";
  dotnet-sdk = dotnet-sdk;
  dotnet-runtime = dotnet-runtime;

  meta = with lib; {
    homepage = "https://github.com/dotnet/diagnostics";
    changelog = "https://github.com/dotnet/diagnostics/releases";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
