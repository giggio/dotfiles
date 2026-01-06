{
  lib,
  buildDotnetGlobalTool,
  dotnet-sdk,
  dotnet-runtime,
}:

buildDotnetGlobalTool {
  pname = "httprepl";
  nugetName = "Microsoft.dotnet-httprepl";
  version = "8.0.0";

  nugetSha256 = "sha256-049MUmyjIweAYd2SdsKVghRl+nhVf0HhhjC+UQfvszI=";
  dotnet-sdk = dotnet-sdk;
  dotnet-runtime = dotnet-runtime;

  meta = with lib; {
    homepage = "https://github.com/dotnet/HttpRepl";
    changelog = "https://github.com/dotnet/HttpRepl/releases";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
