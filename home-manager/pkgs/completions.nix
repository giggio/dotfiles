{ stdenv, installShellFiles, kubectl, nodejs }:

stdenv.mkDerivation {
  pname = "extra-completions";
  version = "0.0.1";
  src = ./completions;
  nativeBuildInputs = [ installShellFiles ];
  # todo: remove node when https://github.com/NixOS/nixpkgs/issues/316507 is fixed
  buildPhase =''
    ${kubectl}/bin/kubectl completion bash | sed 's/kubectl/kubecolor/g' > kubecolor.bash
    ${nodejs}/bin/node --completion-bash > node.bash
  '';
  installPhase = ''
    installShellCompletion *.bash
  '';
}