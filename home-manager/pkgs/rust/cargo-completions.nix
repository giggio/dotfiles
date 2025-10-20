{ bash, rust-toolchain-fenix, coreutils, system }:

derivation {
  name = "cargo-completions";
  builder = "${bash}/bin/bash";
  args = [
    "-c"
    ''
      PATH="${coreutils}/bin"
      mkdir -p "$out/share/bash-completion/completions/"
      cp "${rust-toolchain-fenix}/etc/bash_completion.d/cargo" "$out/share/bash-completion/completions/cargo"
    ''
  ];
  inherit system;
}
