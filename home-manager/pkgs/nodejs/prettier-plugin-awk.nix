{ buildNpmPackage, fetchFromGitHub, lib }:

buildNpmPackage rec {
  pname = "prettier-plugin-awk";
  version = "0.3.1";

  src = fetchFromGitHub {
    owner = "Beaglefoot";
    repo = pname;
    rev = "v0.3.1";
    hash = "sha256-r1dFQAryITTXK2EIP1SO/czj2/206yMMRr6VZjVB8qQ=";
  };

  npmDepsHash = "sha256-WepRHtx5zOo/1FYqAN6WmSy6xMggafzje70TJXQ/HR8=";
  npmBuildScript = "compile";
  postPatch =
    ''
      cp ${./prettier-plugin-awk-package-lock.json} ./package-lock.json
      set +e
      patch --ignore-whitespace --verbose -u package.json -i <(cat <<EOF
      --- package.json	2024-06-03 03:36:32.166186687 -0300
      +++ package.json.patched	2024-06-03 03:35:25.566618477 -0300
      @@ -17,6 +17,9 @@
          "format:watch": "find out/ | entr -c -r yarn prettier --plugin .",
          "test": "yarn compile && mocha"
        },
      +  "bin": {
      +    "prettier-plugin-awk": "out/index.js"
      +  },
        "dependencies": {
          "prettier": "2.5.1",
          "tree-sitter": "0.20.6",

      EOF
      )
      if [ $? -ne 0 ]; then
        echo "Failed to patch package.json"
        if [ -f package.json.rej ]; then
          cat package.json.rej
        fi
        exit 1
      fi
      set -e
    '';

  # The prepack script runs the build script, which we'd rather do in the build phase.
  npmPackFlags = [ "--ignore-scripts" ];

  NODE_OPTIONS = "";

  meta = with lib; {
    description = "AWK plugin for Prettier code formatter";
    homepage = "https://github.com/Beaglefoot/prettier-plugin-awk";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
