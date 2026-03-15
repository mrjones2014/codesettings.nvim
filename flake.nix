{
  description = "Dev shell";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
      self,
      nixpkgs,
      flake-utils,
      treefmt-nix,
      neovim-nightly-overlay,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        treefmt-eval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
        treefmt-wrapper = treefmt-eval.config.build.wrapper;
      in
      rec {
        formatter = treefmt-wrapper;
        devShells = {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              jq
              just
              remarshal
              luajitPackages.busted
              luajitPackages.argparse
              selene
              treefmt-wrapper
            ];
          };
          ci = pkgs.mkShell {
            inputsFrom = [ devShells.default ];
            buildInputs = [ pkgs.neovim ];
          };
          ci-nightly = pkgs.mkShell {
            inputsFrom = [ devShells.default ];
            buildInputs = [ neovim-nightly-overlay.packages.${system}.default ];
          };
        };
        checks = {
          formatting = treefmt-eval.config.build.check self;
          selene = pkgs.callPackage (import ./checks/selene.nix) { inherit self pkgs; };
          statix = pkgs.callPackage (import ./checks/statix.nix) { inherit self pkgs; };
          generated-files = pkgs.callPackage (import ./checks/generated-files.nix) { inherit self pkgs; };
        };
      }
    );
}
