{ stdenv, emptyDirectory }:

stdenv.mkDerivation {
  name = "wslview";
  src = emptyDirectory;
  installPhase = ''
    mkdir -p $out/bin $out/share/applications
    cp ${./wslview} $out/bin/wslview
    cp ${./wslview.desktop} $out/share/applications/wslview.desktop
  '';
}
