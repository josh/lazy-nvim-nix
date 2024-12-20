{
  projectRootFile = "flake.nix";
  programs = {
    # keep-sorted start
    actionlint.enable = true;
    deadnix.enable = true;
    keep-sorted.enable = true;
    nixfmt.enable = true;
    prettier.enable = true;
    shellcheck.enable = true;
    shfmt.enable = true;
    statix.enable = true;
    stylua.enable = true;
    taplo.enable = true;
    # keep-sorted end
  };
}
