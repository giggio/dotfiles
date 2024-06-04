{ pkgs ? import <nixpkgs> {}, ... }:

pkgs.stdenv.mkDerivation {
  name = "kubectl-aliases";
  src = builtins.fetchGit {
    url = "https://github.com/giggio/kubectl-aliases.git";
    ref = "newstuff";
    rev = "7a8d93a5b2adc03d46f9d5ee719632328b409d56";
  };
  installPhase = ''
    mkdir -p $out/bin
    cp .kubecolor_aliases $out/bin/kubecolor_aliases.bash
    cp .kubecolor_aliases.nu $out/bin/kubecolor_aliases.nu
  '';
}
