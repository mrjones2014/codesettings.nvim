{ self, pkgs, ... }:
pkgs.runCommand "generated-files"
  {
    nativeBuildInputs = with pkgs; [
      jq
      just
      luajitPackages.argparse
      neovim
    ];
  }
  ''
    export HOME=$(mktemp -d)
    cp -r ${self}/. ./source/
    chmod -R u+w ./source
    cd ./source

    just build doc

    diff -rq . ${self} || {
      echo
      echo "Error: Generated files are out of date."
      echo "Please run 'just build doc' and commit the results."
      exit 1
    }

    touch $out
  ''
