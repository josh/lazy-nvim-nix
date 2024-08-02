{
  projectRootFile = "flake.nix";
  programs = {
    actionlint.enable = true;
    deadnix.enable = true;
    nixfmt.enable = true;
    prettier.enable = true;
    shellcheck.enable = true;
    shfmt.enable = true;
    statix.enable = true;
    stylua.enable = true;
    taplo.enable = true;
  };
}
