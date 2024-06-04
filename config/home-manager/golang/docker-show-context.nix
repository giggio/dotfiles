{ pkgs, ... }:

pkgs.buildGoModule rec {
  pname = "docker-show-context";
  version = "1.1.1";

  src = pkgs.fetchFromGitHub {
    owner = "pwaller";
    repo = pname;
    rev = "19f133f08f92074bb8a6bb89f482532e5632d18b";
    hash = "sha256-aMNonNI+WlaBOm8jZPiNeTGPa1yU39EHsx/9q6pe3ao=";
  };
  vendorHash = "sha256-nc6g6YiIuLbLheimRG/Bp8QfPHETFkE6/raZbXvrqC8=";

  meta = with pkgs.lib; {
    description = "Show where time is wasted during the context upload of `docker build`";
    homepage = "https://github.com/pwaller/docker-show-context";
    license = licenses.mit;
    platforms = platforms.linux;
  };

}
