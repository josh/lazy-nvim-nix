{
  path,
  lib,
  stdenv,
  stdenvNoCC,
  fetchFromGitHub,
  symlinkJoin,
  vimPlugins,
  # keep-sorted start
  ast-grep,
  bat,
  cargo,
  chafa,
  curl,
  darwin,
  delta,
  fd,
  fish,
  fzf,
  gcc,
  ghostscript,
  gnutar,
  go,
  gzip,
  imagemagick,
  jdk,
  lazygit,
  mermaid-cli,
  nodejs_24,
  php83,
  php83Packages,
  python312Packages,
  ripgrep,
  ruby,
  shfmt,
  sqlite,
  stylua,
  tectonic,
  trash-cli,
  tree-sitter,
  ueberzugpp,
  unzip,
  viu,
  wget,
  yq-go,
  # keep-sorted end
}:
let
  /*
    Pads a string with a leading zero if it is less than two characters long.

    Type: pad :: string -> string
    Example:
      pad "1"
      => "01"
  */
  pad = s: if builtins.stringLength s < 2 then "0" + s else s;

  /*
    Converts a Unix timestamp to a date string in the format "YYYY-MM-DD".

    Type: dateFromUnix :: int -> string
    Example:
      dateFromUnix 1609459200
      => "2021-01-01"
  */
  dateFromUnix =
    t:
    let
      days = t / 86400;
      z = days + 719468;
      era = z / 146097;
      doe = z - era * 146097;
      yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
      y = yoe + era * 400;
      doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
      mp = (5 * doy + 2) / 153;
      d = doy - (153 * mp + 2) / 5 + 1;
      m = mp + (if mp < 10 then 3 else -9);
      y' = y + (if m <= 2 then 1 else 0);
    in
    "${toString y'}-${pad (toString m)}-${pad (toString d)}";

  /*
    Formats a derivation name from a plugin name and version.

    Type: formatDerivationName :: { name: string, version: string } -> string
    Example:
      formatDerivationName { name = "lazy.nvim", version = "0.0.1" }
      => "lazyvim-plugin-lazy-nvim-0.0.1"
  */
  formatDerivationName =
    { name, version }:
    let
      pname = builtins.replaceStrings [ "." ] [ "-" ] name;
    in
    "lazyvim-plugin-${pname}-${version}";

  /*
    Apply list of patches to derivation, returning a new one.

    Type: applyPatches :: drv -> [ string ] -> drv
  */
  applyPatches =
    src: patches:
    stdenvNoCC.mkDerivation (finalAttrs: {
      name = formatDerivationName { inherit (src.meta) name version; };
      inherit src patches;
      inherit (src) meta;
      installPhase = ''
        runHook preInstall
        cp -r . $out
        runHook postInstall
      '';
      passthru = {
        spec = src.spec // {
          dir = "${finalAttrs.finalPackage}";
        };
      }
      // lib.attrsets.optionalAttrs (src ? extraPackages) { inherit (src) extraPackages; };
    });

  /*
    Make a lazy.nvim plugin spec.
    See <https://lazy.folke.io/spec>
  */
  makeLazySpec =
    name: node: drv:
    assert node.original.type == "github";
    {
      inherit name;
      dir = "${drv}";
      url = "https://github.com/${node.original.owner}/${node.original.repo}";
      branch = node.original.ref;
      commit = node.locked.rev;
      pin = true;
    };

  # Build a lazy.nvim plugin package from flake.lock node.
  buildPlugin =
    name: node:
    let
      version = dateFromUnix node.locked.lastModified;
      src = fetchFromGitHub {
        name = formatDerivationName { inherit name version; };
        inherit (node.locked) owner repo rev;
        sha256 = node.locked.narHash;
      };
      meta = src.meta // {
        inherit name version;
      };
      spec = makeLazySpec name node src;
    in
    src.overrideAttrs (previousAttrs: {
      inherit meta;
      passthru = (previousAttrs.passthru or { }) // {
        inherit spec;
      };
    });

  lockfile = builtins.fromJSON (builtins.readFile ./plugins/flake.lock);

  pluginNodes = builtins.removeAttrs lockfile.nodes [
    "root"
    "mason-registry"
  ];

  # Re-key plugins by canonical plugin name (with dots preserved).
  # Flake input names use hyphens (e.g. "octo-nvim") since dots are invalid
  # in flake identifiers, but node.original.repo retains the real name
  # (e.g. "octo.nvim"). Fall back to the flake input name when the repo
  # name doesn't match (e.g. catppuccin's repo is just "nvim").
  pluginName =
    flakeName: node:
    let
      inherit (node.original) repo;
    in
    if repo == flakeName || builtins.match ".*[.].*" repo != null then repo else flakeName;

  duplicatePluginNames = builtins.attrNames (
    lib.attrsets.filterAttrs (_: count: count > 1) (
      builtins.foldl' (acc: name: acc // { ${name} = (acc.${name} or 0) + 1; }) { } (
        map (flakeName: pluginName flakeName pluginNodes.${flakeName}) (builtins.attrNames pluginNodes)
      )
    )
  );

  plugins =
    assert lib.assertMsg (duplicatePluginNames == [ ]) ''
      plugin name collision: multiple inputs in plugins/flake.nix map to: ${toString duplicatePluginNames}
      Rename or remove one of the conflicting inputs.'';
    lib.mapAttrs' (
      flakeName: node:
      let
        name = pluginName flakeName node;
      in
      {
        inherit name;
        value = buildPlugin name node;
      }
    ) pluginNodes;

  LazyVim-deps = builtins.fromJSON (builtins.readFile ./plugins/LazyVim.json);

  masonRegistry =
    let
      name = "mason-registry";
      node = lockfile.nodes.mason-registry;
    in
    fetchFromGitHub {
      name = formatDerivationName {
        inherit name;
        version = dateFromUnix node.locked.lastModified;
      };
      inherit (node.locked) owner repo rev;
      sha256 = node.locked.narHash;
    };

  treesitterGrammars =
    p: with p; [
      # keep-sorted start
      bash
      c
      css
      diff
      dtd
      html
      javascript
      jsdoc
      json
      latex
      lua
      luadoc
      luap
      markdown
      markdown_inline
      printf
      python
      query
      regex
      scss
      svelte
      toml
      tsx
      typescript
      typst
      vim
      vimdoc
      vue
      xml
      yaml
      # keep-sorted end
    ];

  nvim-treesitter-install-dir = symlinkJoin {
    name = "nvim-treesitter-install-dir";
    paths = (vimPlugins.nvim-treesitter.withPlugins treesitterGrammars).dependencies;
  };

  mapNestedAttrs =
    f: attrset:
    lib.recurseIntoAttrs (
      builtins.mapAttrs (_a: bs: lib.recurseIntoAttrs (builtins.mapAttrs f bs)) attrset
    );

  pluginOverrides = {
    "lazy.nvim" = applyPatches plugins."lazy.nvim" [
      "${path}/pkgs/applications/editors/vim/plugins/patches/lazy-nvim/no-helptags.patch"

      # Disable rtp healthcheck that @folke is too lazy to fix it
      # Randomly errors when a nix path contains "paq"
      # https://github.com/folke/lazy.nvim/issues/798
      ./plugins/lazy-nvim-rtp.patch
    ];

    "LazyVim" = plugins."LazyVim" // {
      extras = mapNestedAttrs (
        repo: slug:
        let
          drv =
            plugins'.${repo} or (throw ''
              plugin "${repo}" is listed in plugins/LazyVim.json but has no pin in plugins/flake.nix.
              Add the input there, then run:
                nix flake update --flake ./plugins
                nix run .#LazyVimPlugins.updateScript
            '');
        in
        if drv.spec.url == "https://github.com/${slug}" then
          drv
        else
          throw ''
            plugin "${repo}": plugins/LazyVim.json says upstream is "${slug}" but plugins/flake.nix pins ${drv.spec.url}.
            The repository has likely moved. Update the input to github:${slug}, then run:
              nix flake update --flake ./plugins
              nix run .#LazyVimPlugins.updateScript''
      ) LazyVim-deps;
    };

    # Fixes "blink_cmp_fuzzy lib is not downloaded/built" warning
    # See pkgs/tests/blink-cmp-checkhealth.nix
    "blink.cmp" = vimPlugins.blink-cmp // {
      spec =
        builtins.removeAttrs plugins."blink.cmp".spec [
          "branch"
          "commit"
        ]
        // {
          dir = "${vimPlugins.blink-cmp}";
        };
      extraPackages = [ curl ];
    };

    "conform.nvim" = plugins."conform.nvim" // {
      extraPackages = [
        fish
        shfmt
        stylua
      ];
    };

    "grug-far.nvim" = plugins."grug-far.nvim" // {
      extraPackages = [ ast-grep ];
    };

    "fzf-lua" = plugins."fzf-lua" // {
      spec = plugins."fzf-lua".spec // {
        dependencies = [
          (plugins."mini.icons".spec // { opts = { }; })
        ];
      };
      extraPackages = [
        bat
        chafa
        delta
        fd
        fzf
        ripgrep
        ueberzugpp
        viu
      ];
    };

    # Fix sqlite3 not available warning
    "snacks.nvim" = plugins."snacks.nvim" // {
      spec =
        plugins."snacks.nvim".spec
        // {
          priority = 1000;
        }
        // (lib.attrsets.optionalAttrs stdenv.hostPlatform.isLinux {
          opts.picker.db.sqlite3_path = "${sqlite.out}/lib/libsqlite3.so";
        })
        // (lib.attrsets.optionalAttrs stdenv.hostPlatform.isDarwin {
          opts.picker.db.sqlite3_path = "${sqlite.out}/lib/libsqlite3.dylib";
        });
      extraPackages = [
        ghostscript
        imagemagick
        lazygit
        mermaid-cli
        tectonic
      ]
      ++ lib.lists.optionals stdenv.hostPlatform.isLinux [ trash-cli ]
      ++ lib.lists.optionals stdenv.hostPlatform.isDarwin [ darwin.trash ];
    };

    "mason.nvim" = plugins."mason.nvim" // {
      spec = plugins."mason.nvim".spec // {
        opts = {
          registries = [ "file:${masonRegistry}" ];
        };
      };
      extraPackages =
        let
          python312WithPip = python312Packages.python.withPackages (ps: with ps; [ pip ]);
        in
        [
          # keep-sorted start
          cargo
          curl
          gnutar
          go
          gzip
          jdk
          nodejs_24
          php83
          php83Packages.composer
          python312WithPip
          ruby
          unzip
          wget
          yq-go
          # keep-sorted end
        ];
    };

    "nvim-treesitter" = vimPlugins.nvim-treesitter // {
      spec =
        builtins.removeAttrs plugins."nvim-treesitter".spec [
          "branch"
          "commit"
        ]
        // {
          dir = "${vimPlugins.nvim-treesitter}";
          opts.install_dir = "${nvim-treesitter-install-dir}";
        };
      installDir = nvim-treesitter-install-dir;
      extraPackages = [
        gcc
        gnutar
        tree-sitter
      ];
    };
  };

  plugins' = plugins // pluginOverrides;
in
lib.recurseIntoAttrs plugins'
