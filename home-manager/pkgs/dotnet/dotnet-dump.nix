{ lib, buildDotnetGlobalTool , dotnet-sdk }:

buildDotnetGlobalTool {
  pname = "dotnet-dump";
  version = "8.0.510501";

  nugetSha256 = "sha256-H7Z4EA/9G3DvVuXbnQJF7IJMEB2SkzRjTAL3eZMqCpI=";
  dotnet-sdk = dotnet-sdk;

  meta = with lib; {
    homepage = "https://github.com/dotnet/diagnostics";
    changelog = "https://github.com/dotnet/diagnostics/releases";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
