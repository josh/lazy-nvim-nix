{
  lib,
  stdenv,
  runCommand,
  neovim,
  xclip,
  glibcLocales,
  pluginName ? "all",
  loadLazyPluginName ? null,
  checkOk ? true,
  checkError ? checkWarning,
  checkWarning ? false,
}:
let
  lazyLoadCmd = if loadLazyPluginName != null then [ "+Lazy! load ${loadLazyPluginName}" ] else [ ];
  checkCmd =
    if pluginName == null || pluginName == "all" then
      [ "+checkhealth" ]
    else
      [ "+checkhealth ${pluginName}" ];
in
runCommand "checkhealth-${pluginName}"
  {
    __structuredAttrs = true;

    neovimBin = lib.getExe neovim;
    nvimArgs =
      [
        "--headless"
      ]
      ++ lazyLoadCmd
      ++ checkCmd
      ++ [
        "+w!out.txt"
        "+q"
      ];

    check = {
      ok = checkOk;
      error = checkError;
      warning = checkWarning;
    };

    nativeBuildInputs = lib.lists.optionals stdenv.isLinux [ xclip ];

    env = {
      DISPLAY = lib.optionalString stdenv.isLinux ":0";
      LOCALE_ARCHIVE = lib.optionalString stdenv.isLinux "${glibcLocales}/lib/locale/locale-archive";
      LANG = "en_US.UTF-8";
    };
  }
  ''
    mkdir -p .config/nvim
    touch .config/nvim/init.lua

    HOME="$PWD" timeout 30s "$neovimBin" "''${nvimArgs[@]}"
    cat out.txt

    ok_count=$(grep --count " OK " <out.txt || true)
    error_count=$(grep --count " ERROR " <out.txt || true)
    warning_count=$(grep --count " WARNING " <out.txt || true)
    echo "$ok_count ok, $error_count errors, $warning_count warnings"

    if [[ -n "''${check[error]}" && "$error_count" -gt 0 ]]; then
      echo "Expected no errors, but were $error_count" >&2
      return 1
    elif [[ -n "''${check[warning]}" && "$warning_count" -gt 0 ]]; then
      echo "Expected no warnings, but were $warning_count" >&2
      return 1
    elif [[ -n "''${check[ok]}" && "$ok_count" -eq 0 ]]; then
      echo "Expected at least one OK" >&2
      return 1
    else
      touch $out
    fi
  ''
