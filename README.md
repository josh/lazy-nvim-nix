# lazy-nvim-nix

A Nix Flake for working with [lazy.nvim](https://github.com/folke/lazy.nvim) [Neovim](https://neovim.io/) plugins and the [LazyVim](https://github.com/LazyVim/LazyVim) distribution.

## Installation

Add as an input to your flake:

```nix
{
  inputs.lazy-nvim-nix.url = "github:josh/lazy-nvim-nix";

  outputs = { self, lazy-nvim-nix }: {
    homeModules.default = {
      programs.neovim.finalPackage = lazy-nvim-nix.packages.x86_64-linux.LazyVim;
    };

    nixosModules.default = {
      programs.neovim.finalPackage = lazy-nvim-nix.packages.x86_64-linux.default;
    };
  };
}
```

## Usage

### `packages.${system}.lazy-nvim`

```nix
{
  environment.systemPackages = [
    pkgs.lazy-nvim.override {
      spec = [ "lualine.nvim" ];
    };
  ];
}
```

### `packages.${system}.LazyVim`

```nix
{
  home.packages = [
    pkgs.LazyVim.override {
      lazyVimExtras = [ "lazyvim.plugins.extras.coding.copilot" ];
    };
  ];
}
```

### `packages.${system}.default`

Alias for `packages.${system}.lazy-nvim`.

### `overlays.default`

```nix
{
  nixpkgs.overlays = [ lazy-nvim-nix.overlays.default ];
  programs.neovim.finalPackage = pkgs.lazynvimPlugins.LazyVim.override {
    lazyVimExtras = [ "lazyvim.plugins.extras.coding.copilot" ];
  };
}
```

### `lib.defaultLazyOpts`

### `lib.setupLazyLua :: { pkgs, spec, opts } -> string`
