{ pkgs ? import <nixpkgs> { }, ... }:

# see urls and details at: https://developer.hashicorp.com/terraform/install
pkgs.stdenv.mkDerivation rec {
  name = "terraform";
  version = "1.8.4";
  src =
    let
      arch = {
        "x86_64-linux" = "amd64";
        "aarch64-linux" = "arm64";
        "armv6-linux" = "arm";
        "armv7-linux" = "arm";
        "armv8-linux" = "arm";
      }."${pkgs.system}";
    in
    pkgs.fetchzip {
      url = "https://releases.hashicorp.com/terraform/${version}/terraform_${version}_linux_${arch}.zip";
      sha256 = "sha256-0AyFvnivHHl6etUNrno3+RddjZPINOSYjJX6Mclp+Fk=";
      stripRoot = false;
    };

  installPhase = ''
    mkdir -p $out/bin
    cp terraform $out/bin/
    chmod +x $out/bin/terraform
  '';

  meta = with pkgs.lib; {
    homepage = "https://www.hashicorp.com/products/terraform";
    changelog = "https://github.com/hashicorp/terraform/releases";
    license = licenses.bsl11;
    platforms = platforms.linux;
  };
}
