{
  description = "Dev shell";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
  outputs =
    {
      nixpkgs,
      flake-utils,
      neovim-nightly-overlay,
      ...
    }:
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
        devShells.ci-nightly = pkgs.mkShell {
          inputsFrom = [ devShell ];
          buildInputs = [ neovim-nightly-overlay.packages.${system}.default ];
        };
      }
    );
}
