{
  stdenv,
  lib,
  symlinkJoin,
}:

let

  mkPkg =
    { sha256, url }:
    let
      name = builtins.baseNameOf url;
    in
    stdenv.mkDerivation {
      name = "zellij_${name}";
      version = "0.0.1";
      dontUnpack = true;
      installPhase =
        let
          file = builtins.fetchurl { inherit sha256 url; };
        in
        ''
          mkdir -p $out/share/zellij/
          cp ${file} $out/share/zellij/${name}
        '';

      meta = with lib; {
        homepage = "https://zellij.dev/documentation/plugins.html";
        license = licenses.mit;
        platforms = platforms.linux;
      };
    };
in
symlinkJoin {
  name = "zellij_plugins";
  paths = [
    (mkPkg {
      sha256 = "sha256:0lyxah0pzgw57wbrvfz2y0bjrna9bgmsw9z9f898dgqw1g92dr2d";
      url = "https://github.com/dj95/zjstatus/releases/download/v0.22.0/zjstatus.wasm";
    })
    (mkPkg {
      sha256 = "sha256:17bir2z85ip7x6zndy94x5wdrpqv2py3wf116kadn3jw0blmav4k";
      url = "https://github.com/b0o/zjstatus-hints/releases/download/v0.1.4/zjstatus-hints.wasm";
    })
    (mkPkg {
      sha256 = "sha256:00y1mkyvwr1zvsamqym4syc6avkfps9wy7yky1sa1dzldawcjqav";
      url = "https://github.com/sharph/zellij-nvim-nav-plugin/releases/download/v1.0.0/zellij-nvim-nav-plugin.wasm";
    })
  ];
  meta.priority = 10;
}
