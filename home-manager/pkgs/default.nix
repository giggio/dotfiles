{ pkgs }:

with pkgs;
{
  dotnet-sdk = with dotnetCorePackages; combinePackages
    [
      sdk_8_0
      sdk_9_0
    ];
  dotnet-runtime = dotnetCorePackages.sdk_9_0;
  dotnet-tools = callPackage ./dotnet/dotnet-tools.nix { inherit dotnet-sdk; inherit dotnet-runtime; };
  dotnet-install = callPackage ./dotnet/dotnet-install.nix { };
  extra-completions = callPackage ./completions.nix { };
  terraform = callPackage ./unfree/terraform.nix { };
  vault = callPackage ./unfree/vault.nix { };
  rust-toolchain = fenix.stable.withComponents [ "cargo" "clippy" "rust-src" "rustc" "rustfmt" ];
  cargo-completions = callPackage ./rust/cargo-completions.nix { };
  cspell-lsp = callPackage ./nodejs/cspell-lsp.nix { };
  loadtest = callPackage ./nodejs/loadtest.nix { };
  prettier-plugin-awk = callPackage ./nodejs/prettier-plugin-awk.nix { };
  chart-releaser = callPackage ./golang/chart-releaser.nix { };
  docker-show-context = callPackage ./golang/docker-show-context.nix { };
  ketall = callPackage ./golang/ketall.nix { };
  kubectl-aliases = callPackage ./aliases/kubectl-aliases.nix { };
  code-lldb = callPackage ./code-lldb.nix {
    vscode-lldb = vscode-extensions.vadimcn.vscode-lldb;
  };
  my_gems = callPackage ./ruby/gems.nix { };
  custom-xcompose = callPackage ./xcompose.nix { };
  cspellls = callPackage ./cspellls.nix {
    code-spell-checker = vscode-extensions.streetsidesoftware.code-spell-checker;
  };
  cspell-dict-pt-br = callPackage ./nodejs/cspell-dict-pt-br.nix { };
}
