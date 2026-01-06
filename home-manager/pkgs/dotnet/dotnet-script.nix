{
  lib,
  buildDotnetGlobalTool,
  dotnet-sdk,
  dotnet-runtime,
}:

buildDotnetGlobalTool {
  pname = "dotnet-script";
  version = "1.6.0";

  nugetSha256 = "sha256-R2z02Orakl6T7nfmNLr3HSbBS2yxFhWRP1imy9B+Tqo=";
  dotnet-sdk = dotnet-sdk;
  dotnet-runtime = dotnet-runtime;

  meta = with lib; {
    homepage = "https://github.com/dotnet-script/dotnet-script";
    changelog = "https://github.com/dotnet-script/dotnet-script/releases";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
