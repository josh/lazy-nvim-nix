# usage:
#   NIX_PATH=nixpkgs=/path/to/nixpkgs:to-lua=/path/to/to-lua.nix
#   nix eval --file lazyvim-spec.nix --raw
let
  pkgs = import <nixpkgs> { };
  inherit (pkgs) lib;

  toLua = import <to-lua>;

  notNull = v: v != null;
  compactList = builtins.filter notNull;
  compactAttrs = lib.filterAttrs (_: notNull);

  # Give a nixpkgs vim plugin name, return the GitHub owner and name.
  # Returns null if not found or not a GitHub URL.
  #
  #   getPluginGitHubNameWithOwner "noice-nvim"
  #   # => "folke/noice.nvim"
  #
  getPluginGitHubNameWithOwner =
    name:
    let
      pkg = pkgs.vimPlugins.${name};
      isDerivation = lib.attrsets.isDerivation pkg;
      hasMeta = builtins.hasAttr "meta" pkg;
      homepage = pkg.meta.homepage or "";
      matches = builtins.match "https://github.com/([^/]+/[^#/]+).*" homepage;
      hasMatches = builtins.isList matches;
      match = builtins.elemAt matches 0;
      ok = isDerivation && hasMeta && hasMatches;
      unsafeResult = if ok then match else null;
      safeResult = builtins.tryEval unsafeResult;
    in
    if safeResult.success then safeResult.value else null;

  # Build index mapping GitHub name with owner to nixpkgs vim plugin.
  githubToVimPlugins =
    let
      vimPluginNames = builtins.attrNames pkgs.vimPlugins;
      mapPackageName =
        name:
        let
          nameWithOwner = getPluginGitHubNameWithOwner name;
        in
        if nameWithOwner != null then
          {
            name = nameWithOwner;
            value = pkgs.vimPlugins.${name};
          }
        else
          builtins.trace "No GitHub repository for pkgs.vimPlugins.\"${name}\"" null;
    in
    builtins.listToAttrs (compactList (builtins.map mapPackageName vimPluginNames));

  # Look up a nixpkgs vim plugin by GitHub owner and name.
  # 
  #   getVimPluginByGitHub "folke/noice.nvim"
  #   # => pkgs.vimPlugins.noice-nvim
  #
  getVimPluginByGitHub =
    nameWithOwner:
    let
      hasPlugin = builtins.hasAttr nameWithOwner githubToVimPlugins;
      plugin = githubToVimPlugins.${nameWithOwner};
    in
    if hasPlugin then plugin else null;

  # Nested set of LazyVim plugin imports to it's plugin name and GitHub repo.
  #
  #   "lazyvim.plugins" = {
  #     "bufferline.nvim" = "akinsho/bufferline.nvim";
  #     "catppuccin" = "catppuccin/nvim";
  #     ...
  #   };
  lazyvimPluginImportRepos = builtins.fromJSON (
    builtins.readFile (builtins.getEnv "LAZYVIM_PLUGINS")
  );

  # List of LazyVim extra import modules.
  #
  #   [
  #     "lazyvim.plugins.extras.coding.copilot"
  #     "lazyvim.plugins.extras.editor.telescope"
  #   ]
  #
  lazyvimPluginImportExtras = builtins.fromJSON (builtins.getEnv "LAZYVIM_EXTRAS");

  # Always import core plugins.
  lazyvimPluginImports = [ "lazyvim.plugins" ] ++ lazyvimPluginImportExtras;

  # Nested set of LazyVim plugin imports to it's nixpkgs vim plugin.
  #
  #   "lazyvim.plugins" = {
  #     "bufferline.nvim" = pkgs.vimPlugins.bufferline-nvim;
  #     "catppuccin" = pkgs.vimPlugins.catppuccin-nvim;
  #     ...
  #   };
  #
  lazyvimPluginImportPkgs = builtins.mapAttrs (
    _: deps: (compactAttrs (builtins.mapAttrs (_: getVimPluginByGitHub) deps))
  ) lazyvimPluginImportRepos;

  flatPlugins = builtins.foldl' (a: b: a // lazyvimPluginImportPkgs.${b}) { } lazyvimPluginImports;
  lockSpec = lib.attrsets.mapAttrsToList (name: dir: { inherit name dir; }) flatPlugins;

  spec = [
    {
      name = "LazyVim";
      dir = pkgs.vimPlugins.LazyVim;
      import = "lazyvim.plugins";
    }
  ] ++ lockSpec;
in
''return ${(toLua { inherit lib; }).toLua spec}''
