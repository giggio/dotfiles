{ buildNpmPackage, fetchFromGitHub, lib, stdenv, nodejs, pnpm_9 }:

let
  pnpm = pnpm_9;
in
stdenv.mkDerivation (finalAttrs: rec {
  pname = "cspell-dict-pt-br";
  version = "2.4.0";

  src = fetchFromGitHub {
    owner = "streetsidesoftware";
    repo = "cspell-dicts";
    rev = "@cspell/dict-pt-br@${version}";
    hash = "sha256-0hAWjvcbjjhY6S8ZjMtsTimiT8ZCtsf2fINbtib8GTw=";
  };

  nativeBuildInputs = [
    nodejs
    pnpm.configHook
  ];

  pnpmWorkspaces = [ "@cspell/dict-pt-br" ];

  pnpmDeps = pnpm.fetchDeps {
    inherit (finalAttrs) pname version src;
    inherit (finalAttrs) pnpmWorkspaces;
    fetcherVersion = 2;
    hash = "sha256-h1E8Ai3M7Z4rDSB+I6sGT0nqgYchwe2k8ni9qnzhhkw=";
  };

  buildPhase = ''
    runHook preBuild
    pnpm --filter=@cspell/dict-pt-br run build
    pnpm --filter=@cspell/dict-pt-br run prepare:dictionary
    mkdir -p $out/share/cspell-dict-pt-br
    cp dictionaries/pt_BR/pt_BR.trie.gz dictionaries/pt_BR/cspell-ext.json $out/share/cspell-dict-pt-br/
    runHook postBuild
  '';

  meta = with lib; {
    description = "Various cspell dictionaries";
    homepage = "https://cspell.org";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
  };
})
