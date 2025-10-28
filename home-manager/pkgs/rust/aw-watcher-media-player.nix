{ rust-toolchain-fenix, lib, fetchFromGitHub, makeRustPlatform, pkg-config, dbus, openssl }:

(makeRustPlatform { cargo = rust-toolchain-fenix; rustc = rust-toolchain-fenix; }).buildRustPackage rec {
  pname = "aw-watcher-media-player";
  version = "1.1.1";

  src = fetchFromGitHub {
    owner = "2e3s";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-6lVW2hd1nrPEV3uRJbG4ySWDVuFUi/JSZ1HYJFz0KdQ=";
  };

  buildInputs = [ dbus openssl ];

  nativeBuildInputs = [ pkg-config ];

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    outputHashes = {
      "aw-client-rust-0.1.0" = "sha256-fCjVfmjrwMSa8MFgnC8n5jPzdaqSmNNdMRaYHNbs8Bo=";
    };
  };

  postFixup = ''
    patchelf \
      --add-needed ${openssl.out}/lib/libssl.so.3 \
      --add-needed ${openssl.out}/lib/libcrypto.so.3 \
      --add-needed ${dbus.lib}/lib/libdbus-1.so.3 \
      $out/bin/$pname
  '';

  postInstall = ''
    mkdir -p $out/share/$pname
    cp -R visualization $out/share/$pname/visualization
  '';

  meta = with lib; {
    description = "Watcher of system's currently playing media for ActivityWatch";
    homepage = "https://github.com/2e3s/aw-watcher-media-player";
    license = licenses.unlicense;
  };
}
