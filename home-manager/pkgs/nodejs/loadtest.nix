{ buildNpmPackage, fetchFromGitHub, lib }:

buildNpmPackage rec {
  pname = "loadtest";
  version = "8.0.9";

  src = fetchFromGitHub {
    owner = "alexfernandez";
    repo = pname;
    rev = "a0f4b30a4d4d44a2699b9d50625ba727e85d277f";
    hash = "sha256-ezP0PEnn73kAH4s+pk2SN2kL3msTTsBpok5qr2P4RtM=";
  };

  npmDepsHash = "sha256-XM07orPl504FweeexTwP23CwJdoJ2Xl1vA5+thFWfj4=";
  dontNpmBuild = true;
  postPatch =
    ''
      cp ${./loadtest-package-lock.json} ./package-lock.json
    '';

  # The prepack script runs the build script, which we'd rather do in the build phase.
  npmPackFlags = [ "--ignore-scripts" ];

  NODE_OPTIONS = "";

  meta = with lib; {
    description = "Runs a load test on the selected HTTP or WebSockets URL";
    homepage = "https://github.com/alexfernandez/loadtest/";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
