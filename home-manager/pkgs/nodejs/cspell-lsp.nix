{ buildNpmPackage, fetchFromGitHub, lib, bun }:

buildNpmPackage rec {
  pname = "cspell-lsp";
  version = "1.1.2";

  nativeBuildInputs = [ bun ];
  buildInputs = [ bun ];

  src = fetchFromGitHub {
    owner = "vlabo";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-lwUeq3edeZNe2BjpLMnuWkMj4W+6urWIgy4GDjajM5M=";
  };

  npmDepsHash = "sha256-R00j7aa1XOLorWhZMEpXVE5WuR5qLaYs/26QWYB8HXA=";
  postPatch =
    ''
      patch --ignore-whitespace --verbose -p1 -i ${./cspell-lsp.package-lock.json.patch}
    '';

  # The prepack script runs the build script, which we'd rather do in the build phase.
  npmPackFlags = [ "--ignore-scripts" ];

  NODE_OPTIONS = "";

  meta = with lib; {
    description = "A simple source code spell checker for helix (and NeoVim)";
    homepage = "https://github.com/vlabo/cspell-lsp/";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
  };
}
