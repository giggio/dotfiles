{
  stdenv,
  bash,
  coreutils,
}:

derivation {
  inherit (stdenv.hostPlatform) system;
  name = "dotnet-install";
  builder = "${bash}/bin/bash";
  args =
    let
      file = builtins.fetchurl {
        url = "https://raw.githubusercontent.com/dotnet/install-scripts/46ddb46b6c97c74698224acd4e6ab534373382ea/src/dotnet-install.sh";
        sha256 = "sha256:0v2mcxicb9q399vv06pf8vwcbyb5iqy0zpqbdy1amhpsl0k83kpw";
      };
    in
    [
      "-c"
      ''
        PATH="${coreutils}/bin"
        mkdir -p $out/bin
        cp ${file} $out/bin/dotnet-install
        chmod +x $out/bin/dotnet-install
      ''
    ];
}
