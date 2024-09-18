{
  inputs = {
    "lazy.nvim" = {
      url = "github:folke/lazy.nvim";
      flake = false;
    };
    LazyVim = {
      url = "github:LazyVim/LazyVim";
      flake = false;
    };
  };

  outputs = inputs: { };
}
