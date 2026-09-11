{ pkgs, ... }:
{
  programs = {
    stylua.enable = true;
    nixfmt.enable = true;
    yamlfmt.enable = true;
    just.enable = true;
    actionlint.enable = true;
  };
  settings.formatter.tombi = {
    command = "${pkgs.tombi}/bin/tombi";
    options = [
      "format"
      "--offline"
    ];
    includes = [ "*.toml" ];
  };
}
