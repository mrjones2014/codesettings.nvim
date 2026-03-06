{ self, pkgs, ... }:
pkgs.runCommand "selene"
  {
    nativeBuildInputs = [ pkgs.selene ];
  }
  ''
    selene ${self}/lua ${self}/spec --config ${self}/selene.toml
    touch $out
  ''
