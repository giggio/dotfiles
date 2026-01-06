{
  bash,
  rust-toolchain-fenix,
  coreutils,
  stdenv,
}:

derivation {
  inherit (stdenv.hostPlatform) system;
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
}
