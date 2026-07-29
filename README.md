# lazy-nvim-nix

[LazyVim](https://www.lazyvim.org/), fully pre-configured, as a single Nix
package.

Every plugin is pinned through a flake lock and served from the Nix store —
nothing is downloaded at editor startup, `lazy.nvim` never runs `git`, and the
whole configuration is exercised by `:checkhealth`-based tests in CI. Treesitter
parsers come pre-compiled, mason runs against a pinned offline registry, and the
language toolchain LazyVim expects (LSP servers' runtimes, formatters, ripgrep,
fzf, lazygit, …) is already on the editor's `PATH`.

## Try it

```sh
nix run github:josh/lazy-nvim-nix
```

That's the full LazyVim distribution. The [Neovide](https://neovide.dev) flavor:

```sh
nix run github:josh/lazy-nvim-nix#LazyVim-neovide
```

## Install

As a flake input:

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

Or through the overlay, which adds everything under `pkgs.lazy-nvim-nix`:

```nix
{
  nixpkgs.overlays = [ lazy-nvim-nix.overlays.default ];
  environment.systemPackages = [ pkgs.lazy-nvim-nix.LazyVim ];
}
```

| attribute                          | what it is                                                               |
| ---------------------------------- | ------------------------------------------------------------------------ |
| `LazyVim` (= `default`)            | Neovim wrapped with the full LazyVim distribution                        |
| `lazy-nvim`                        | Neovim wrapped with lazy.nvim and an empty spec — bring your own plugins |
| `LazyVim-neovide` / `lazy-neovide` | Neovide launching the corresponding editor                               |
| `lazy-nvim-config`                 | a standalone generated `init.lua`, for use with any `nvim -u`            |
| `plugins` (overlay only)           | the pinned plugin set; each entry carries a ready-made lazy.nvim spec    |

## What you get out of the box

- LazyVim with its default plugins, colorscheme, keymaps, and autocmds.
- Treesitter parsers and queries pre-installed from nixpkgs — no `:TSInstall`,
  no compiler needed at runtime.
- mason.nvim pointed at a pinned, offline copy of the mason registry.
- A working toolchain appended to the editor's `PATH` (suffixed, so tools from
  your project or shell always win over the bundled ones).
- lazy.nvim configured for immutability: `install.missing = false`, update
  checker and change detection off, all plugin `dir`s in the Nix store.

Your own `~/.config/nvim/init.lua` is **not** loaded — the configuration is the
package. Customization happens in Nix, below. (Modules under
`~/.config/nvim/lua/` remain requirable if you reference them from
`customLuaRC`.)

## Configuring

LazyVim's own documentation configures everything through files in
`~/.config/nvim` — options in `lua/config/options.lua`, plugins as spec
fragments in `lua/plugins/*.lua`, extras via `:LazyExtras`. Each pattern from
<https://www.lazyvim.org/configuration> has a direct equivalent here, passed to
`LazyVim.override`. A complete example:

```nix
pkgs.lazy-nvim-nix.LazyVim.override {
  globals = {
    autoformat = false;
    opt = {
      relativenumber = false;
    };
  };
  extras = [ "lazyvim.plugins.extras.lang.go" ];
  extraSpec = [
    (pkgs.lazy-nvim-nix.plugins."dial.nvim".spec // { lazy = false; })
    (pkgs.lazy-nvim-nix.plugins."persistence.nvim".spec // { enabled = false; })
  ];
  extraPackages = [ pkgs.gopls ];
  opts = {
    ui = {
      border = "double";
    };
  };
}
```

### Options, globals, and the leader key

LazyVim: `lua/config/options.lua`.

```lua
vim.g.autoformat = false
vim.opt.relativenumber = false
```

Here: the `globals` argument. A timing subtlety makes the obvious translation
wrong: LazyVim loads its _own_ options **inside** `require("lazy").setup()`
and assigns unconditionally, so a `vim.g.autoformat = false` written plainly
in `customLuaRC` (which runs before setup) is silently overwritten moments
later. `globals` values are applied on the `User LazyVimOptions` event LazyVim
fires after loading its options — after LazyVim's defaults, before any plugin
or extra is imported. Plain keys become `vim.g` variables; the `opt` attrset
becomes `vim.opt` assignments:

```nix
LazyVim.override {
  globals = {
    autoformat = false;
    opt = {
      relativenumber = false;
    };
  };
}
```

The equivalent escape hatch in raw Lua, for anything more involved:

```lua
vim.api.nvim_create_autocmd("User", {
  pattern = "LazyVimOptions",
  callback = function()
    vim.g.autoformat = false
    vim.opt.relativenumber = false
  end,
})
```

Keymaps and autocmds carry one timing caveat: `customLuaRC` runs before
LazyVim installs its own defaults (those load on the `VeryLazy` event), so a
mapping meant to _override_ a LazyVim default would itself be overridden
moments later — and `vim.g.mapleader` isn't set yet, so a `<leader>` mapping
made directly in `customLuaRC` binds against the wrong leader. New mappings on
fresh keys work directly if you spell the key out; to override a default,
hook the `User LazyVimKeymaps` (or `User LazyVimAutocmds`) event LazyVim
fires after loading its own:

```lua
vim.keymap.set("n", "<Space>gd", vim.diagnostic.open_float)

vim.api.nvim_create_autocmd("User", {
  pattern = "LazyVimKeymaps",
  callback = function()
    vim.keymap.set("n", "<leader>l", my_replacement, { desc = "Mine" })
  end,
})
```

### Adding a plugin

LazyVim: a spec fragment in `lua/plugins/`.

```lua
return {
  { "monaqa/dial.nvim", lazy = false },
}
```

Here: an entry in `extraSpec`, built from the pinned plugin set. Each
`plugins."<name>"` carries a `.spec` with `dir` pointing at the store path, so
extending it with `//` is the whole job:

```nix
LazyVim.override {
  extraSpec = [
    (pkgs.lazy-nvim-nix.plugins."dial.nvim".spec // { lazy = false; })
  ];
}
```

List the available pinned plugins with:

```sh
nix eval --impure --json --expr 'builtins.attrNames (import <nixpkgs> {
  overlays = [ (builtins.getFlake "github:josh/lazy-nvim-nix").overlays.default ];
}).lazy-nvim-nix.plugins'
```

A plugin that isn't pinned works too — any derivation containing the plugin can
be a `dir`:

```nix
extraSpec = [
  {
    name = "my-plugin.nvim";
    dir = "${pkgs.fetchFromGitHub {
      owner = "me";
      repo = "my-plugin.nvim";
      rev = "...";
      hash = "...";
    }}";
    lazy = false;
  }
];
```

### Overriding a built-in plugin's options

LazyVim: a fragment for the same plugin; `opts` tables deep-merge with the
distribution's defaults.

```lua
return {
  { "folke/tokyonight.nvim", opts = { transparent = true } },
}
```

Here: identical semantics — lazy.nvim merges fragments by plugin name, and an
attrset `opts` becomes a Lua table:

```nix
extraSpec = [
  (pkgs.lazy-nvim-nix.plugins."tokyonight.nvim".spec // {
    opts = {
      transparent = true;
    };
  })
];
```

One upstream caveat carries over directly: table merging replaces _lists_
wholesale. Where the LazyVim docs tell you to use an `opts` function to append
to a list, use `lib.generators.mkLuaInline` to embed that function from Nix:

```nix
extraSpec = [
  (pkgs.lazy-nvim-nix.plugins."nvim-treesitter".spec // {
    opts = lib.generators.mkLuaInline ''
      function(_, opts)
        vim.list_extend(opts.ensure_installed, { "zig" })
      end
    '';
  })
];
```

`mkLuaInline` is the general escape hatch: any spec field that upstream
documents as a Lua function (`config`, `keys` entries with callbacks, `cond`,
…) is expressible with it.

### Changing the colorscheme (and other LazyVim settings)

LazyVim's own settings — `colorscheme`, `icons`, `news`, `kind_filter` — are
plugin `opts` on the `LazyVim` spec itself, not lazy.nvim options:

```lua
return {
  { "LazyVim/LazyVim", opts = { colorscheme = "catppuccin" } },
}
```

Here: the same fragment, through `extraSpec`:

```nix
extraSpec = [
  (pkgs.lazy-nvim-nix.plugins."LazyVim".spec // {
    opts = {
      colorscheme = "catppuccin";
    };
  })
];
```

### Disabling a plugin

LazyVim:

```lua
return {
  { "folke/persistence.nvim", enabled = false },
}
```

Here:

```nix
extraSpec = [
  (pkgs.lazy-nvim-nix.plugins."persistence.nvim".spec // { enabled = false; })
];
```

### Extras

LazyVim: `:LazyExtras`, or an import line in the lazy.nvim spec:

```lua
{ import = "lazyvim.plugins.extras.lang.go" },
```

Here: the `extras` argument, which emits the import _and_ puts every plugin the
extra needs on the runtime path. Names are validated at evaluation time — a
typo fails the build with the full list of available extras.

```nix
LazyVim.override {
  extras = [ "lazyvim.plugins.extras.lang.go" ];
  extraPackages = [ pkgs.gopls ];
}
```

Language extras usually expect their toolchain (LSP server, formatter,
debugger) to be installable via mason or already present. Mason cannot install
anything here — the store is read-only — so upstream `ensure_installed`
examples are inert; add those tools with `extraPackages` instead.
`:LazyExtras` itself is read-only in this setup: extras are part of the
package, not runtime state. The `lazyvim.json` file LazyVim uses for that
state is generated at build time from the `extras` argument and lives in the
Nix store, so `:LazyExtras` shows your enabled extras, toggling one lasts
only until restart, and the packaged editor never reads or rewrites a
`~/.config/nvim/lazyvim.json` shared with a stock LazyVim install.

### lazy.nvim's own options

LazyVim: the `opts` table passed to `require("lazy").setup()` in
`lua/config/lazy.lua`.

Here: the `opts` argument, deep-merged over this flake's defaults
(`lib.defaultLazyOpts`):

```nix
LazyVim.override {
  opts = {
    ui = {
      border = "double";
    };
  };
}
```

Precedence: arguments set on `LazyVim.override` win; arguments set on a custom
`lazy-nvim` package (next section) survive only where `LazyVim` doesn't set
them.

### Extra tools and Lua libraries

Anything the editor should be able to spawn goes in `extraPackages` (appended
to the wrapper's `PATH` as a suffix, so your shell and project tools still
win):

```nix
LazyVim.override {
  extraPackages = [ pkgs.gh ];
}
```

Lua rocks for plugins that need them are wired through the underlying wrapper.
Note that a custom `lazy-nvim` package's `opts` survives unless
`LazyVim.override` sets it, while its `customLuaRC`, `spec`, and
`extraPackages` are always replaced by the LazyVim wrapper — use
`customLuaRC`/`extraSpec`/`extraPackages` on `LazyVim.override` instead:

```nix
LazyVim.override {
  lazy-nvim = pkgs.lazy-nvim-nix.lazy-nvim.override {
    extraLuaPackages = ps: [ ps.magick ];
  };
}
```

## Building your own editor (without LazyVim)

The same machinery works from an empty spec. `lazy-nvim` is Neovim + lazy.nvim

- whatever you give it:

```nix
pkgs.lazy-nvim-nix.lazy-nvim.override {
  customLuaRC = ''
    vim.g.mapleader = " "
  '';
  spec = [
    (pkgs.lazy-nvim-nix.plugins."tokyonight.nvim".spec // {
      lazy = false;
      priority = 1000;
      config = lib.generators.mkLuaInline ''
        function()
          vim.cmd([[colorscheme tokyonight]])
        end
      '';
    })
    (pkgs.lazy-nvim-nix.plugins."which-key.nvim".spec // { lazy = true; })
  ];
}
```

If you'd rather keep your own Neovim and only generate the configuration,
`lazy-nvim-config` produces a standalone `init.lua` with the same
`customLuaRC`/`spec`/`opts` arguments, usable as `nvim -u ${config}`.

## Maintenance

- Plugin pins live in `plugins/flake.nix` / `plugins/flake.lock` and are bumped
  daily by dependabot.
- After a `LazyVim` bump changes its plugin list, regenerate the dependency
  scan: `nix run .#LazyVimPlugins.updateScript` (CI's `LazyVimPlugins-outdated`
  check tells you when).
- `nix run .#check-plugin-sources` reports pins whose branch no longer matches
  the upstream default branch (`--fix` repairs them).
- `nix flake check` runs the whole test suite, including enforced
  `:checkhealth` for the full configuration and per-plugin checks. See
  `AGENTS.md` for development conventions.
