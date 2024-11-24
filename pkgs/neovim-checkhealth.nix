{
  lib,
  stdenv,
  runCommand,
  neovim,
  glibcLocales,
  pluginName ? "all",
  loadLazyPluginName ? null,
  checkOk ? true,
  checkError ? checkWarning,
  checkWarning ? false,
}:
runCommand "checkhealth-${pluginName}"
  {
    NEOVIM_BIN = lib.getExe neovim;
    CHECK_PLUGIN_NAME = pluginName;
    LAZY_LOAD_PLUGIN_NAME = loadLazyPluginName;
    CHECK_OK = if checkOk then "1" else "";
    CHECK_ERROR = if checkError then "1" else "";
    CHECK_WARNING = if checkWarning then "1" else "";
    LOCALE_ARCHIVE = lib.optionalString stdenv.isLinux "${glibcLocales}/lib/locale/locale-archive";
    LANG = "en_US.UTF-8";
  }
  ''
    mkdir -p .config/nvim
    touch .config/nvim/init.lua

    CHECK_CMD="+checkhealth"
    if [[ -n "$CHECK_PLUGIN_NAME" && "$CHECK_PLUGIN_NAME" != "all" ]]; then
      CHECK_CMD="+checkhealth $CHECK_PLUGIN_NAME"
    fi

    LAZY_LOAD_CMD=""
    if [[ -n "$LAZY_LOAD_PLUGIN_NAME" ]]; then
      LAZY_LOAD_CMD="+Lazy! load $LAZY_LOAD_PLUGIN_NAME"
    fi

    HOME="$PWD" "$NEOVIM_BIN" --headless "$LAZY_LOAD_CMD" "$CHECK_CMD" '+w!out.txt' +q
    cat out.txt

    ok_count=$(grep --count " OK " <out.txt || true)
    error_count=$(grep --count " ERROR " <out.txt || true)
    warning_count=$(grep --count " WARNING " <out.txt || true) 
    echo "$ok_count ok, $error_count errors, $warning_count warnings"

    if [[ -n "$CHECK_OK" && "$ok_count" -eq 0 ]]; then
      echo "Expected at least one OK" >&2
      return 1
    elif [[ -n "$CHECK_ERROR" && "$error_count" -gt 0 ]]; then
      echo "Expected no errors, but were $error_count" >&2
      return 1
    elif [[ -n "$CHECK_WARNING" && "$warning_count" -gt 0 ]]; then
      echo "Expected no warnings, but were $warning_count" >&2
      return 1
    else
      mv out.txt "$out"
    fi
  ''
