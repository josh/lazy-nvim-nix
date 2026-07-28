{
  lib,
  stdenv,
  writeText,
  writeShellScriptBin,
  runCommand,
  neovim,
  moreutils,
  xclip,
  glibcLocales,
  pluginName ? "all",
  loadLazyPluginName ? null,
  checkOk ? true,
  checkError ? true,
  checkWarning ? true,
  ignoreLines ? [ ],
  optionalIgnoreLines ? [ ],
}:
let
  vim-script-runner = writeText "checkhealth-${pluginName}.vim" ''
    doautocmd UIEnter
    ${if loadLazyPluginName != null then "Lazy! load ${loadLazyPluginName}" else ""}
    lua vim.wait(3000, function() return vim.g.did_very_lazy == true end, 50)
    ${if pluginName == null || pluginName == "all" then "checkhealth" else "checkhealth ${pluginName}"}
    w!out.txt
    qall!
  '';
  kitty-binstub = writeShellScriptBin "kitty" "exit 0";
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
    inherit ignoreLines optionalIgnoreLines;

    nativeBuildInputs = [
      kitty-binstub
      moreutils
    ]
    ++ lib.lists.optionals stdenv.hostPlatform.isLinux [ xclip ];

    env = {
      DISPLAY = lib.optionalString stdenv.hostPlatform.isLinux ":0";
      LANG = "en_US.UTF-8";
      LOCALE_ARCHIVE = lib.optionalString stdenv.hostPlatform.isLinux "${glibcLocales}/lib/locale/locale-archive";
      SNACKS_KITTY = "1";
    };
  }
  ''
    mkdir -p .config/nvim
    touch .config/nvim/init.lua

    exit_code=0
    HOME="$PWD" timeout --kill-after=10s 300s "$neovimBin" "''${nvimArgs[@]}" 2>err.txt || exit_code=$?

    echo "-- stdout --"
    cat out.txt || true
    echo "-- stderr --"
    cat err.txt || true
    echo "--"

    if [ "$exit_code" -eq 124 ] || [ "$exit_code" -eq 137 ]; then
      echo "nvim timed out (exit $exit_code)"
      exit 1
    elif [ "$exit_code" -ne 0 ]; then
      echo "nvim exited with code $exit_code"
      exit 1
    fi

    for ignoreLine in "''${optionalIgnoreLines[@]}"; do
      { grep --invert-match --fixed-strings -- "$ignoreLine" out.txt || true; } | sponge out.txt
      { grep --invert-match --fixed-strings -- "$ignoreLine" err.txt || true; } | sponge err.txt
    done

    if grep "^E[0-9]\+: " err.txt; then
      echo "nvim reported errors on stderr"
      exit 1
    fi
    if grep "Failed to run" err.txt; then
      echo "plugin setup failed"
      exit 1
    fi

    for ignoreLine in "''${ignoreLines[@]}"; do
      if grep --fixed-strings --quiet -- "$ignoreLine" out.txt; then
        echo "Found: $ignoreLine"
        { grep --invert-match --fixed-strings -- "$ignoreLine" out.txt || true; } | sponge out.txt
      else
        echo "Missing: $ignoreLine"
        echo "not found in stdout, consider removing from 'ignoreLines'"
        exit 1
      fi
    done

    ok_count=$(grep --count " OK " <out.txt || true)
    error_count=$(grep --count " ERROR " <out.txt || true)
    warning_count=$(grep --count " WARNING " <out.txt || true)
    echo "$ok_count ok, $error_count errors, $warning_count warnings"

    if [[ -n "''${check[error]}" && "$error_count" -gt 0 ]]; then
      echo "Expected no errors, but were $error_count"
      exit 1
    elif [[ -n "''${check[warning]}" && "$warning_count" -gt 0 ]]; then
      echo "Expected no warnings, but were $warning_count"
      exit 1
    elif [[ -n "''${check[ok]}" && "$ok_count" -eq 0 ]]; then
      echo "Expected at least one OK"
      exit 1
    else
      touch $out
    fi
  ''
