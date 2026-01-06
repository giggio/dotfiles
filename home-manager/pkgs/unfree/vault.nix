{
  stdenv,
  fetchzip,
  lib,
}:

# see urls and details at: https://developer.hashicorp.com/vault/install
stdenv.mkDerivation rec {
  name = "vault";
  version = "1.18.2";
  src =
    let
      arch =
        {
          "x86_64-linux" = "amd64";
          "aarch64-linux" = "arm64";
          "armv6-linux" = "arm";
          "armv7-linux" = "arm";
          "armv8-linux" = "arm";
        }
        ."${stdenv.hostPlatform.system}";
    in
    fetchzip {
      url = "https://releases.hashicorp.com/vault/${version}/vault_${version}_linux_${arch}.zip";
      sha256 = "sha256-l1S/E6NYP6fjPcD7CdNlMKQfbrSCtxIsDjiykmu2+Pc=";
      stripRoot = false;
    };

  installPhase = ''
    mkdir -p $out/bin
    cp vault $out/bin/
    chmod +x $out/bin/vault
  '';

  meta = with lib; {
    homepage = "https://www.hashicorp.com/products/vault";
    changelog = "https://developer.hashicorp.com/vault/docs/release-notes";
    license = licenses.bsl11;
    platforms = platforms.linux;
  };
}
