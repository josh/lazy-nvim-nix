{
  lib,
  runCommand,
  neovim,
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
      return 1
    elif [[ -n "$CHECK_ERROR" && "$error_count" -gt 0 ]]; then
      return 1
    elif [[ -n "$CHECK_WARNING" && "$warning_count" -gt 0 ]]; then
      return 1
    else
      mv out.txt "$out"
    fi
  ''
