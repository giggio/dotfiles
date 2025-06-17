{ buildNpmPackage, fetchFromGitHub, lib, stdenv, nodejs, pnpm_9 }:

let
  pnpm = pnpm_9;
in
stdenv.mkDerivation (finalAttrs: rec {
  pname = "cspell-tools";
  version = "9.1.1";

  src = fetchFromGitHub {
    owner = "streetsidesoftware";
    repo = "cspell";
    rev = "v${version}";
    hash = "sha256-p7VDmmlDR90jjeUPMcEXm8115KqDwWiU15VgLAfeOH0=";
  };

  nativeBuildInputs = [
    nodejs
    pnpm.configHook
  ];

  pnpmDeps = pnpm.fetchDeps {
    inherit (finalAttrs) pname version src;
    hash = "sha256-nActhN7EOxE3fNiKKI+G+REzQg9bjQQ6j94EGGf0qLk=";
  };

  buildPhase = ''
    runHook preBuild
    pnpm run build
    mkdir -p $out/bin
    mkdir -p $out/share/cspell
    cp -R . $out/share/cspell/
    ln -s $out/share/cspell/packages/cspell-tools/bin.mjs $out/bin/cspell-tools
    ln -s $out/share/cspell/packages/cspell-tools/bin.mjs $out/bin/cspell-tools-cli
    runHook postBuild
  '';

  meta = with lib; {
    description = "Tools to assist with the development of cSpell";
    homepage = "https://cspell.org";
    license = licenses.mit;
    platforms = platforms.linux;
  };
})
