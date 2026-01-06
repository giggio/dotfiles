{
  buildGoModule,
  fetchFromGitHub,
  git,
  lib,
}:

buildGoModule rec {
  pname = "chart-releaser";
  version = "1.6.1";

  src = fetchFromGitHub {
    owner = "helm";
    repo = pname;
    rev = "v1.6.1";
    hash = "sha256-8+O9JErEB1Z/zlrWm975v5Qf0YG0lbPcjY5LlDKw8U4=";
  };
  vendorHash = "sha256-S/V1kTgD/cXaJNYpPPNjM9ya2zv6Bsy/YBn7I/1EjwI=";
  nativeBuildInputs = [ git ];

  meta = with lib; {
    description = "Hosting Helm Charts via GitHub Pages and Releases";
    homepage = "https://github.com/helm/chart-releaser";
    license = licenses.asl20;
    platforms = platforms.linux;
  };
}
