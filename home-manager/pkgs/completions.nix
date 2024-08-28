{ stdenv, installShellFiles, kubectl, nodejs }:

stdenv.mkDerivation {
  pname = "extra-completions";
  version = "0.0.1";
  src = ./completions;
  nativeBuildInputs = [ installShellFiles ];
  buildPhase = ''
    ${kubectl}/bin/kubectl completion bash | sed 's/kubectl/kubecolor/g' > kubecolor.bash
    echo '_completion_loader home-manager; complete -o default -F _home-manager_completions hm' > hm.bash
  '';
  installPhase = ''
    installShellCompletion *.bash
  '';
}
