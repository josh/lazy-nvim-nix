# lazy-nvim-nix

A Nix Flake for working with [lazy.nvim](https://github.com/folke/lazy.nvim) [Neovim](https://neovim.io/) plugins and the [LazyVim](https://github.com/LazyVim/LazyVim) distribution.

## Installation

Add as an input to your flake:

```nix
{
  inputs.lazy-nvim-nix.url = "github:josh/lazy-nvim-nix";

  outputs = { self, lazy-nvim-nix }: {
    homeModules.default = {
      home.packages = [ lazy-nvim-nix.packages.x86_64-linux.LazyVim ];
    };

    nixosModules.default = {
      environment.systemPackages = [ lazy-nvim-nix.packages.x86_64-linux.default ];
    };
  };
}
```

## Usage

### `overlays.default`

Adds a `lazy-nvim-nix` attribute set to nixpkgs containing `plugins`,
`lazy-nvim`, `LazyVim`, `lazy-nvim-config`, `lazy-neovide`, `LazyVim-neovide`
and `lib`:

```nix
{
  nixpkgs.overlays = [ lazy-nvim-nix.overlays.default ];
  environment.systemPackages = [ pkgs.lazy-nvim-nix.LazyVim ];
}
```

### `packages.${system}.lazy-nvim`

Neovim wrapped with lazy.nvim and a nix-managed plugin spec:

```nix
{
  environment.systemPackages = [
    (pkgs.lazy-nvim-nix.lazy-nvim.override {
      spec = [ pkgs.lazy-nvim-nix.plugins."lualine.nvim".spec ];
    })
  ];
}
```

### `packages.${system}.LazyVim`

Neovim wrapped with the full LazyVim distribution and its default plugins.

### `packages.${system}.default`

Alias for `packages.${system}.LazyVim`.

### `packages.${system}.lazy-neovide` / `LazyVim-neovide`

[Neovide](https://neovide.dev) wrapped around the corresponding Neovim package.

### `lib.defaultLazyOpts`

Default `require("lazy").setup()` options used by the wrapped packages.

### `lib.setupLazyLua :: { pkgs, spec, opts } -> string`

Renders a lazy.nvim bootstrap snippet for use in a custom `init.lua`. `opts`
are passed through as-is; merge `lib.defaultLazyOpts` yourself if wanted.
