{ stdenv, fetchFromGitHub, emptyDirectory, code-spell-checker }:

stdenv.mkDerivation {
  name = "cspellls";
  src = emptyDirectory;
  installPhase = ''
    mkdir -p $out/bin/
    echo '#!/usr/bin/env bash' > $out/bin/cspellls
    cat << EOF > $out/bin/cspellls
    #!/usr/bin/env bash
    node ${code-spell-checker}/share/vscode/extensions/streetsidesoftware.code-spell-checker/packages/_server/dist/main.cjs "\$@"
    EOF
    chmod +x "$out/bin/cspellls"
  '';
}

