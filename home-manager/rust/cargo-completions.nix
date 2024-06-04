{ pkgs ? import <nixpkgs> { }, rust }:

pkgs.stdenv.mkDerivation {
  name = "cargo-completions";
  src = pkgs.emptyDirectory;
  installPhase = ''
    mkdir -p "$out/share/bash-completion/completions/"
    cp "${rust}/etc/bash_completion.d/cargo" "$out/share/bash-completion/completions/cargo"
  '';
}
