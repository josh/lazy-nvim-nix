{
  lib,
  stdenv,
  writeText,
  runCommand,
  neovim,
  moreutils,
  xclip,
  glibcLocales,
  pluginName ? "all",
  loadLazyPluginName ? null,
  checkOk ? true,
  checkError ? checkWarning,
  checkWarning ? false,
  ignoreLines ? [ ],
}:
let
  vim-script-runner = writeText "checkhealth-${pluginName}.vim" ''
    doautocmd UIEnter
    ${if loadLazyPluginName != null then "Lazy! load ${loadLazyPluginName}" else ""}
    sleep 3
    ${if pluginName == null || pluginName == "all" then "checkhealth" else "checkhealth ${pluginName}"}
    w!out.txt
    qall!
  '';
in
runCommand "checkhealth-${pluginName}"
  {
    __structuredAttrs = true;

    neovimBin = lib.getExe neovim;
    nvimArgs = [
      "--headless"
      "-S"
      "${vim-script-runner}"
    ];

    check = {
      ok = checkOk;
      error = checkError;
      warning = checkWarning;
    };
    inherit ignoreLines;

    nativeBuildInputs = [ moreutils ] ++ lib.lists.optionals stdenv.isLinux [ xclip ];

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
    echo "-- stdout --"
    cat out.txt
    echo "-- stdout --"

    for ignoreLine in "''${ignoreLines[@]}"; do
      if grep --fixed-strings --quiet -- "$ignoreLine" out.txt; then
        echo "Found: $ignoreLine"
        grep --invert-match --fixed-strings -- "$ignoreLine" out.txt | sponge out.txt
      else
        echo "Missing: $ignoreLine"
        echo "not found in stdout, consider removing from 'ignoreLines'"
        return 1
      fi
    done

    ok_count=$(grep --count " OK " <out.txt || true)
    error_count=$(grep --count " ERROR " <out.txt || true)
    warning_count=$(grep --count " WARNING " <out.txt || true)
    echo "$ok_count ok, $error_count errors, $warning_count warnings"

    if [[ -n "''${check[error]}" && "$error_count" -gt 0 ]]; then
      echo "Expected no errors, but were $error_count"
      return 1
    elif [[ -n "''${check[warning]}" && "$warning_count" -gt 0 ]]; then
      echo "Expected no warnings, but were $warning_count"
      return 1
    elif [[ -n "''${check[ok]}" && "$ok_count" -eq 0 ]]; then
      echo "Expected at least one OK"
      return 1
    else
      touch $out
    fi
  ''
