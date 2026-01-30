{
  description = "Dev shell";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      rec {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            jq
            just
            stylua
            selene
            luajitPackages.busted
            luajitPackages.argparse
          ];
        };
        devShells.ci = pkgs.mkShell {
          inputsFrom = [ devShell ];
          buildInputs = [ pkgs.neovim ];
        };
      }
    );
}
