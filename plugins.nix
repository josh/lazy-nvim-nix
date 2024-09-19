{ pkgs }:
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
      pname = builtins.replaceStrings [ "." ] [ "-" ] name;
      version = dateFromUnix node.locked.lastModified;
      srcName = "lazynvimplugin-${pname}-${version}";
      src = pkgs.fetchFromGitHub {
        name = srcName;
        inherit (node.locked) owner repo rev;
        sha256 = node.locked.narHash;
      };
      meta = src.meta // {
        inherit version;
      };
      spec = makeLazySpec name node src;
    in
    src // { inherit meta spec; };

  lockfile = builtins.fromJSON (builtins.readFile ./plugins/flake.lock);

  pluginNodes = builtins.removeAttrs lockfile.nodes [ "root" ];

  plugins = builtins.mapAttrs buildPlugin pluginNodes;
in
plugins
// {
  "lazy.nvim" = pkgs.vimUtils.buildVimPlugin {
    pname = "lazy.nvim";
    inherit (plugins."lazy.nvim".meta) version;
    src = plugins."lazy.nvim";
    meta.homepage = plugins."lazy.nvim".meta.homepage;
  };
}
