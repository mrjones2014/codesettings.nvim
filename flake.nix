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

        # Tree-sitter parsers needed by panvimdoc
        treesitterParsers = with pkgs.vimPlugins.nvim-treesitter-parsers; [
          markdown
          markdown_inline
          vimdoc
        ];
      in
      {
        devShell = pkgs.mkShell {
          buildInputs =
            with pkgs;
            [
              jq
              just
              luajitPackages.argparse
              luajitPackages.busted
              neovim
              panvimdoc
              selene
              stylua
            ]
            ++ treesitterParsers;

          shellHook = ''
            # Add tree-sitter parsers to Neovim's runtimepath
            export NVIM_TREESITTER_PARSERS="${
              pkgs.symlinkJoin {
                name = "treesitter-parsers";
                paths = treesitterParsers;
              }
            }/parser"
          '';
        };
      }
    );
}
