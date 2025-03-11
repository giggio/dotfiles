{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule rec {
  pname = "ketall"; # krew get-all
  version = "1.3.8";

  src = fetchFromGitHub {
    owner = "corneliusweig";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-Mau57mXS78fHyeU0OOz3Tms0WNu7HixfAZZL3dmcj3w=";
  };
  vendorHash = "sha256-lxfWJ7t/IVhIfvDUIESakkL8idh+Q/wl8B1+vTpb5a4=";

  meta = with lib; {
    description = "Like `kubectl get all`, but get really all resources";
    homepage = "https://github.com/corneliusweig/ketall/";
    license = licenses.asl20;
    platforms = platforms.linux;
  };

  postBuild = ''
    cd $GOPATH/bin/
    ln -s ketall kubectl-getall
  '';

}

