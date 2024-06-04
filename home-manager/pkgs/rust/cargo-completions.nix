{ bash, rust, coreutils }:

derivation {
  name = "cargo-completions";
  builder = "${bash}/bin/bash";
  args = [
    "-c"
    ''
      PATH="${coreutils}/bin"
      mkdir -p "$out/share/bash-completion/completions/"
      cp "${rust}/etc/bash_completion.d/cargo" "$out/share/bash-completion/completions/cargo"
    ''
  ];
  system = builtins.currentSystem;
}
