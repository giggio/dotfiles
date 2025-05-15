{ stdenv }:

stdenv.mkDerivation {
  name = "kubectl-aliases";
  src = builtins.fetchGit {
    url = "https://github.com/giggio/kubectl-aliases.git";
    ref = "newstuff";
    rev = "94277201c58670537e482c433bbb665eaaf19c53";
  };
  installPhase = ''
    mkdir -p $out/bin
    cp .kubecolor_aliases $out/bin/kubecolor_aliases.bash
    cp .kubecolor_aliases.nu $out/bin/kubecolor_aliases.nu
  '';
}
