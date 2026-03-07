{ self, pkgs, ... }:
pkgs.runCommand "statix"
  {
    nativeBuildInputs = [ pkgs.statix ];
  }
  ''
    statix check ${self}
    touch $out
  ''
