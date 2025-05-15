{ stdenv }:

stdenv.mkDerivation {
  name = "kubectl-aliases";
  src = builtins.fetchGit {
    url = "https://github.com/giggio/kubectl-aliases.git";
    ref = "newstuff";
    rev = "4f3b4afebdd74e32b284ce68a8f08cdfbc070e90";
  };
  installPhase = ''
    mkdir -p $out/bin
    cp .kubectl_aliases $out/bin/kubectl_aliases.bash
  '';
}
