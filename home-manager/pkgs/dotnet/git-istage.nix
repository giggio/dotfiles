{ lib, buildDotnetGlobalTool, dotnet-sdk }:

buildDotnetGlobalTool {
  pname = "git-istage";
  version = "0.3.108";

  nugetSha256 = "sha256-jslnbY+0FeWvlAuUYEGAHKE3hUJFBMP1JtuKHJrFQJU=";
  dotnet-sdk = dotnet-sdk;

  meta = with lib; {
    homepage = "https://github.com/terrajobst/git-istage";
    changelog = "https://github.com/terrajobst/git-istage/releases";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
