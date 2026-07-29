{
  path,
  lib,
  stdenv,
  stdenvNoCC,
  fetchFromGitHub,
  fetchgit,
  neovimUtils,
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
  glib,
  gnutar,
  go,
  gzip,
  imagemagick,
  jdk,
  lazygit,
  lua-language-server,
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
  gitNodeUrl = node: lib.strings.removeSuffix ".git" node.original.url;

  makeLazySpec =
    name: node: drv:
    assert builtins.elem node.original.type [
      "github"
      "git"
    ];
    {
      inherit name;
      dir = "${drv}";
      url =
        if node.original.type == "github" then
          "https://github.com/${node.original.owner}/${node.original.repo}"
        else
          gitNodeUrl node;
      branch = node.original.ref;
      commit = node.locked.rev;
      pin = true;
    };

  # Build a lazy.nvim plugin package from flake.lock node.
  buildPlugin =
    name: node:
    let
      version = dateFromUnix node.locked.lastModified;
      src =
        if node.original.type == "github" then
          fetchFromGitHub {
            name = formatDerivationName { inherit name version; };
            inherit (node.locked) owner repo rev;
            sha256 = node.locked.narHash;
          }
        else
          fetchgit {
            name = formatDerivationName { inherit name version; };
            url = node.original.url;
            rev = node.locked.rev;
            hash = node.locked.narHash;
          };
      meta = (src.meta or { }) // {
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
    if node.original.type == "git" then
      baseNameOf (gitNodeUrl node)
    else
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

  movedPlugins =
    let
      moved = builtins.fromJSON (builtins.readFile ./plugins/moved.json);
      allSlugs = lib.lists.unique (
        builtins.concatMap builtins.attrValues (builtins.attrValues LazyVim-deps)
      );
      stale = builtins.filter (old: !(builtins.elem old allSlugs)) (builtins.attrNames moved);
    in
    assert lib.assertMsg (stale == [ ]) ''
      stale entries in plugins/moved.json: ${toString stale}
      Upstream LazyVim no longer references these slugs. Delete the entries and repoint
      any remaining aliases.'';
    moved;

  nonLazyVimPlugins = [
    "LazyVim"
    "lazy.nvim"
    "lua-utils.nvim"
    "neorg"
    "pathlib.nvim"
  ];

  orphanPluginNames =
    let
      consumed = lib.lists.unique (
        builtins.concatMap builtins.attrNames (builtins.attrValues LazyVim-deps)
      );
    in
    builtins.filter (name: !(builtins.elem name consumed) && !(builtins.elem name nonLazyVimPlugins)) (
      builtins.attrNames plugins
    );

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

  treesitterGrammars = p: [
    # keep-sorted start
    p.angular
    p.astro
    p.bash
    p.bibtex
    p.c
    p.c_sharp
    p.clojure
    p.cmake
    p.cpp
    p.css
    p.csv
    p.dart
    p.dockerfile
    p.dtd
    p.eex
    p.elixir
    p.elm
    p.erlang
    p.fsharp
    p.git_config
    p.git_rebase
    p.gitattributes
    p.gitcommit
    p.gitignore
    p.gleam
    p.glimmer
    p.glimmer_javascript
    p.glimmer_typescript
    p.go
    p.gomod
    p.gosum
    p.gowork
    p.graphql
    p.haskell
    p.hcl
    p.heex
    p.helm
    p.html
    p.http
    p.java
    p.javascript
    p.jsdoc
    p.json
    p.json5
    p.julia
    p.kotlin
    p.latex
    p.lua
    p.luadoc
    p.luap
    p.markdown
    p.markdown_inline
    p.ninja
    p.nix
    p.nu
    p.ocaml
    p.php
    p.printf
    p.prisma
    p.python
    p.query
    p.r
    p.regex
    p.rego
    p.rnoweb
    p.ron
    p.rst
    p.ruby
    p.rust
    p.scala
    p.scss
    p.solidity
    p.sql
    p.svelte
    p.terraform
    p.thrift
    p.toml
    p.tsx
    p.twig
    p.typescript
    p.typst
    p.vim
    p.vimdoc
    p.vue
    p.xml
    p.yaml
    p.zig
    # keep-sorted end
    p."tree-sitter-norg"
  ];

  diffGrammar = neovimUtils.grammarToPlugin (
    (tree-sitter.buildGrammar {
      language = "diff";
      version = "0.0.0+rev=e7e845f";
      src = fetchFromGitHub {
        owner = "tree-sitter-grammars";
        repo = "tree-sitter-diff";
        rev = "e7e845fc380e8677f9b770dc96d6b7e029daab55";
        hash = "sha256-IgxX5RqnsPu2Sub5gSY85Gv2Z3h3jXUDundFfhMKGpE=";
      };
    }).overrideAttrs
      (previousAttrs: {
        postInstall = (previousAttrs.postInstall or "") + ''
          rm -rf $out/queries
        '';
      })
  );

  transitivePlugins = drv: [ drv ] ++ builtins.concatMap transitivePlugins (drv.dependencies or [ ]);

  nvim-treesitter-install-dir = symlinkJoin {
    name = "nvim-treesitter-install-dir";
    paths = lib.lists.unique (
      [ diffGrammar ]
      ++ builtins.concatMap transitivePlugins (vimPlugins.nvim-treesitter.withPlugins treesitterGrammars)
      .dependencies
    );
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
          canonicalSlug = movedPlugins.${slug} or slug;
          expectedUrl =
            if lib.strings.hasInfix "://" canonicalSlug then
              canonicalSlug
            else
              "https://github.com/${canonicalSlug}";
        in
        if drv.spec.url == expectedUrl then
          drv
        else
          throw ''
            plugin "${repo}": plugins/LazyVim.json says upstream is "${slug}" but plugins/flake.nix pins ${drv.spec.url}.
            The repository has likely moved. Update the input to match, then run:
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

    "nvim-lspconfig" = plugins."nvim-lspconfig" // {
      extraPackages = [ lua-language-server ];
    };

    "neo-tree.nvim" = plugins."neo-tree.nvim" // {
      extraPackages = lib.lists.optionals stdenv.hostPlatform.isLinux [ glib ];
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
        // {
          opts = {
            image = {
              enabled = true;
              math.enabled = false;
            };
          }
          // (lib.attrsets.optionalAttrs stdenv.hostPlatform.isLinux {
            picker.db.sqlite3_path = "${sqlite.out}/lib/libsqlite3.so";
          })
          // (lib.attrsets.optionalAttrs stdenv.hostPlatform.isDarwin {
            picker.db.sqlite3_path = "${sqlite.out}/lib/libsqlite3.dylib";
          });
        };
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

    # Build libfzf at nix build time; the plugin otherwise runs make on load
    # See pkgs/tests/telescope-extra-checkhealth.nix
    "telescope-fzf-native.nvim" =
      let
        built = stdenv.mkDerivation {
          name = formatDerivationName { inherit (plugins."telescope-fzf-native.nvim".meta) name version; };
          src = plugins."telescope-fzf-native.nvim";
          installPhase = ''
            runHook preInstall
            cp -r . $out
            runHook postInstall
          '';
          inherit (plugins."telescope-fzf-native.nvim") meta;
        };
      in
      built
      // {
        spec = plugins."telescope-fzf-native.nvim".spec // {
          dir = "${built}";
        };
      };

    # Pin the file-registry yq lookup: mason needs Go yq semantics, and the
    # wrapper's suffixed PATH lets an incompatible user yq win (EPIPE on spawn)
    "mason.nvim" =
      let
        patched = stdenvNoCC.mkDerivation {
          name = formatDerivationName { inherit (plugins."mason.nvim".meta) name version; };
          src = plugins."mason.nvim";
          dontBuild = true;
          postPatch = ''
            substituteInPlace lua/mason-registry/sources/file.lua \
              --replace-fail 'local yq = vim.fn.exepath "yq"' 'local yq = "${lib.getExe yq-go}"'
          '';
          installPhase = ''
            runHook preInstall
            cp -r . $out
            runHook postInstall
          '';
          inherit (plugins."mason.nvim") meta;
        };
      in
      patched
      // {
        spec = plugins."mason.nvim".spec // {
          dir = "${patched}";
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

  plugins' =
    assert lib.assertMsg (orphanPluginNames == [ ]) ''
      orphaned plugin pins in plugins/flake.nix: ${toString orphanPluginNames}
      Nothing in plugins/LazyVim.json references them. Remove the inputs and run:
        nix flake update --flake ./plugins
      or, if consumed outside LazyVim.json, add them to nonLazyVimPlugins in plugins.nix.'';
    plugins // pluginOverrides;
in
lib.recurseIntoAttrs plugins'
