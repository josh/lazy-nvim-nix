# usage:
#   NIX_PATH=nixpkgs=/path/to/nixpkgs
#   nix eval --file vimplugin-index.nix --json | jq
let
  pkgs = import <nixpkgs> { };
  inherit (pkgs) lib;
  inherit (pkgs) vimPlugins;
  vimPluginNames = builtins.attrNames vimPlugins;

  getPluginGitHubNameWithOwner =
    name:
    let
      pkg = vimPlugins.${name};
      isDerivation = lib.attrsets.isDerivation pkg;
      hasMeta = builtins.hasAttr "meta" pkg;
      homepage = pkg.meta.homepage or "";
      matches = builtins.match "https://github.com/([^/]+/[^#/]+).*" homepage;
      hasMatches = builtins.isList matches;
      match = builtins.elemAt matches 0;
      ok = isDerivation && hasMeta && hasMatches;
    in
    if ok then match else null;

  tryPluginGitHubNameWithOwner =
    name:
    let
      result = builtins.tryEval (getPluginGitHubNameWithOwner name);
    in
    if result.success then result.value else null;

  notNull = x: x != null;

  mapPackageName =
    name:
    let
      nameWithOwner = tryPluginGitHubNameWithOwner name;
    in
    if nameWithOwner != null then
      {
        name = nameWithOwner;
        value = name;
      }
    else
      builtins.trace "No GitHub repository for pkgs.vimPlugins.\"${name}\"" null;

in
builtins.listToAttrs (builtins.filter notNull (builtins.map mapPackageName vimPluginNames))
