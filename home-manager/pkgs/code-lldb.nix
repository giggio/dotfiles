{ stdenv, vscode-lldb, emptyDirectory }:

stdenv.mkDerivation {
  name = "code-lldb";
  src = emptyDirectory;
  installPhase = ''
    mkdir -p $out/bin
    cp -R ${vscode-lldb}/share/vscode/extensions/vadimcn.vscode-lldb/adapter/. $out/bin/
  '';
}
