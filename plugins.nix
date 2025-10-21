{
  path,
  lib,
  stdenv,
  stdenvNoCC,
  fetchFromGitHub,
  vimPlugins,
  # keep-sorted start
  bat,
  cargo,
  chafa,
  curl,
  delta,
  fd,
  fzf,
  gcc,
  ghostscript,
  gnutar,
  go,
  gzip,
  imagemagick,
  jdk,
  julia,
  lazygit,
  mermaid-cli,
  nodePackages,
  nodejs_24,
  php83,
  php83Packages,
  python312Packages,
  ripgrep,
  ruby,
  sqlite,
  tree-sitter,
  ueberzugpp,
  unzip,
  viu,
  wget,
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
    stdenvNoCC.mkDerivation {
      name = formatDerivationName { inherit (src.meta) name version; };
      inherit src patches;
      inherit (src) meta;
      installPhase = ''
        runHook preInstall
        cp -r . $out
        runHook postInstall
      '';
    };

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
    src // { inherit meta spec; };

  lockfile = builtins.fromJSON (builtins.readFile ./plugins/flake.lock);

  pluginNodes = builtins.removeAttrs lockfile.nodes [ "root" ];

  plugins = builtins.mapAttrs buildPlugin pluginNodes;

  LazyVim-deps = builtins.fromJSON (builtins.readFile ./plugins/LazyVim.json);

  mapNestedAttrs =
    f: attrset:
    lib.recurseIntoAttrs (
      builtins.mapAttrs (_a: bs: lib.recurseIntoAttrs (builtins.mapAttrs (b: _c: (f b)) bs)) attrset
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
      extras = mapNestedAttrs (repo: builtins.getAttr repo plugins') LazyVim-deps;
    };

    # Fixes "blink_cmp_fuzzy lib is not downloaded/built" warning
    # See pkgs/tests/blink-cmp-checkhealth.nix
    "blink.cmp" = vimPlugins.blink-cmp // {
      spec = plugins."blink.cmp".spec // {
        dir = "${vimPlugins.blink-cmp}";
      };
      extraPackages = [ curl ];
    };

    "fzf-lua" = plugins."fzf-lua" // {
      spec = plugins."fzf-lua".spec // {
        dependencies = [
          # Either
          # plugins."nvim-web-devicons".spec
          plugins."mini.icons".spec
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
      ];
    };

    "mason.nvim" = plugins."mason.nvim" // {
      extraPackages = [
        cargo
        curl
        gnutar
        go
        gzip
        jdk
        nodePackages.nodejs
        php83
        php83Packages.composer
        (python312Packages.python.withPackages (ps: with ps; [ pip ]))
        ruby
        unzip
        wget
      ]
      ++ (lib.lists.optional (lib.meta.availableOn stdenv.hostPlatform julia) julia);
    };

    "nvim-treesitter" = plugins."nvim-treesitter" // {
      extraPackages = [
        gcc
        nodejs_24
        tree-sitter
      ];
    };
  };

  plugins' = plugins // pluginOverrides;
in
lib.recurseIntoAttrs plugins'
