{ stdenv, fetchFromGitHub }:

stdenv.mkDerivation {
  name = "custom-xcompose";
  src = fetchFromGitHub {
    owner = "raelgc";
    repo = "win_us_intl";
    rev = "cc587940e22728846ec9061696b2c9e8374501a6";
    hash = "sha256-wLSXhZYqQm3rqEd034rXK+iCSMtKAncStcQn8TVuz00=";
  };
  installPhase = ''
    mkdir -p $out/lib/
    cp .XCompose $out/lib/
  '';
}
