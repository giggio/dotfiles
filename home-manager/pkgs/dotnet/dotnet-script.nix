{ lib, buildDotnetGlobalTool , dotnet-sdk }:

buildDotnetGlobalTool {
  pname = "dotnet-script";
  version = "1.5.0";

  nugetSha256 = "sha256-PRcgWOOr1+Tx3DNZYHjGgZ+zxHPSjEGwJsue0DoRXMg=";
  dotnet-sdk = dotnet-sdk;

  meta = with lib; {
    homepage = "https://github.com/dotnet-script/dotnet-script";
    changelog = "https://github.com/dotnet-script/dotnet-script/releases";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
