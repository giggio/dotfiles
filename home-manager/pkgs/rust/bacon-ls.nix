{ rust-toolchain-fenix, lib, fetchFromGitHub, makeRustPlatform, perl }:

(makeRustPlatform { cargo = rust-toolchain-fenix; rustc = rust-toolchain-fenix; }).buildRustPackage rec {
  pname = "bacon-ls";
  version = "0.23.0";

  src = fetchFromGitHub {
    owner = "crisidev";
    repo = pname;
    rev = version;
    sha256 = "sha256-9r+3LzIENjQ4Y3TMXbQjifG5ObMwCqxMfOiLpRwu8Nc=";
  };

  nativeBuildInputs = [ perl ];

  cargoLock.lockFile = "${src}/Cargo.lock";

  meta = with lib; {
    description = "A Language Server for Rust using Bacon diagnostics";
    homepage = "https://github.com/crisidev/bacon-ls";
    license = licenses.mit;
  };
}
