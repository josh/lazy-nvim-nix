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
  lazyLoadCmd = if loadLazyPluginName != null then "+Lazy! load ${loadLazyPluginName}" else null;
  checkCmd =
    if pluginName == null || pluginName == "all" then "+checkhealth" else "+checkhealth ${pluginName}";
in
runCommand "checkhealth-${pluginName}"
  {
    # __structuredAttrs = true;

    NEOVIM_BIN = lib.getExe neovim;
    CHECK_OK = if checkOk then "1" else "";
    CHECK_ERROR = if checkError then "1" else "";
    CHECK_WARNING = if checkWarning then "1" else "";

    LAZY_LOAD_CMD = lazyLoadCmd;
    CHECK_CMD = checkCmd;

    # FIXME: __structuredAttrs not working on Linux
    # nvimArgs =
    #   [
    #     "--headless"
    #   ]
    #   ++ (lib.lists.optional (lazyLoadCmd != null) lazyLoadCmd)
    #   ++ (lib.lists.optional (checkCmd != null) checkCmd)
    #   ++ [
    #     "+w!out.txt"
    #     "+q"
    #   ];

    nativeBuildInputs = lib.lists.optionals stdenv.isLinux [ xclip ];
    DISPLAY = lib.optionalString stdenv.isLinux ":0";
    LOCALE_ARCHIVE = lib.optionalString stdenv.isLinux "${glibcLocales}/lib/locale/locale-archive";
    LANG = "en_US.UTF-8";
  }
  ''
    mkdir -p .config/nvim
    touch .config/nvim/init.lua

    if [ -n "$LAZY_LOAD_CMD" ]; then
      HOME="$PWD" timeout 30s "$NEOVIM_BIN" --headless "$LAZY_LOAD_CMD" "$CHECK_CMD" '+w!out.txt' +q
    else
      HOME="$PWD" timeout 30s "$NEOVIM_BIN" --headless "$CHECK_CMD" '+w!out.txt' +q
    fi
    cat out.txt

    ok_count=$(grep --count " OK " <out.txt || true)
    error_count=$(grep --count " ERROR " <out.txt || true)
    warning_count=$(grep --count " WARNING " <out.txt || true)
    echo "$ok_count ok, $error_count errors, $warning_count warnings"

    if [[ -n "$CHECK_ERROR" && "$error_count" -gt 0 ]]; then
      echo "Expected no errors, but were $error_count" >&2
      return 1
    elif [[ -n "$CHECK_WARNING" && "$warning_count" -gt 0 ]]; then
      echo "Expected no warnings, but were $warning_count" >&2
      return 1
    elif [[ -n "$CHECK_OK" && "$ok_count" -eq 0 ]]; then
      echo "Expected at least one OK" >&2
      return 1
    else
      mv out.txt "$out"
    fi
  ''
