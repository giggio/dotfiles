{ bundlerApp }:

bundlerApp {
  pname = "ruby-lsp";
  gemdir = ./.;
  exes = [ "ruby-lsp" ];
}
