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
  loadAllPlugins ? false,
  checkOk ? true,
  checkError ? true,
  checkWarning ? true,
  minSections ? 7,
  ignoreLines ? [ ],
  optionalIgnoreLines ? [ ],
  stderrIgnoreLines ? [ ],
}:
let
  vim-script-runner = writeText "checkhealth-${pluginName}.vim" ''
    doautocmd UIEnter
    ${if loadLazyPluginName != null then "Lazy! load ${loadLazyPluginName}" else ""}
    lua vim.wait(3000, function() return vim.g.did_very_lazy == true end, 50)
    ${lib.strings.optionalString loadAllPlugins ''
      lua require("lazy").load({ plugins = vim.tbl_keys(require("lazy.core.config").plugins), wait = true })
      lua vim.wait(1000, function() return false end, 100)
    ''}
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
      "-i"
      "NONE"
      "-S"
      "${vim-script-runner}"
    ];

    check = {
      ok = checkOk;
      error = checkError;
      warning = checkWarning;
    };
    inherit
      pluginName
      minSections
      ignoreLines
      optionalIgnoreLines
      stderrIgnoreLines
      ;

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

    if [ ! -s out.txt ]; then
      echo "checkhealth produced no output"
      exit 1
    fi

    if [ "$pluginName" = "all" ]; then
      section_count=$(grep --only-matching "^[a-zA-Z0-9_.-]\+: " out.txt | sort --unique | wc -l)
      echo "$section_count checkhealth sections"
      if [ "$section_count" -lt "$minSections" ]; then
        echo "Expected at least $minSections checkhealth sections"
        exit 1
      fi
    elif ! grep --quiet "^''${pluginName//./\\.}: " out.txt; then
      echo "checkhealth section for $pluginName not found"
      exit 1
    fi

    tr '\r' '\n' <err.txt | { grep --invert-match -E '^checkhealth: |^"out\.txt"|^$' || true; } >err-lines.txt

    for ignoreLine in "''${stderrIgnoreLines[@]}"; do
      if grep --fixed-strings --quiet -- "$ignoreLine" err-lines.txt; then
        echo "Found stderr: $ignoreLine"
        { grep --invert-match --fixed-strings -- "$ignoreLine" err-lines.txt || true; } | sponge err-lines.txt
      fi
    done

    if [ -s err-lines.txt ]; then
      echo "unexpected stderr:"
      cat err-lines.txt
      exit 1
    fi

    mkdir sections
    awk '
      /^={10,}$/ {
        n += 1
        print > ("sections/" n)
        getline hdr
        print hdr > ("sections/" n)
        split(hdr, a, ": ")
        print n "\t" a[1] > "sections.map"
        next
      }
      { print > ("sections/" (n + 0)) }
    ' out.txt
    touch sections.map

    for ignoreLine in "''${ignoreLines[@]}"; do
      scope="''${ignoreLine%%|*}"
      if [ "$scope" = "$ignoreLine" ] || ! [[ "$scope" =~ ^[A-Za-z0-9_.-]+$ ]]; then
        continue
      fi
      line="''${ignoreLine#*|}"
      idx=$(awk -F'\t' -v s="$scope" '$2 == s { print $1; exit }' sections.map)
      if [ -z "$idx" ]; then
        echo "Missing: $ignoreLine"
        echo "section '$scope' not present in checkhealth output"
        exit 1
      fi
      if grep --fixed-strings --quiet -- "$line" "sections/$idx"; then
        echo "Found: $ignoreLine"
        { grep --invert-match --fixed-strings -- "$line" "sections/$idx" || true; } | sponge "sections/$idx"
      else
        echo "Missing: $ignoreLine"
        echo "not found in section '$scope', consider removing from 'ignoreLines'"
        exit 1
      fi
    done

    ls sections | sort --numeric-sort | sed 's|^|sections/|' | xargs cat >out.txt

    for ignoreLine in "''${optionalIgnoreLines[@]}"; do
      if grep --fixed-strings --quiet -- "$ignoreLine" out.txt; then
        echo "Optional: $ignoreLine"
        { grep --invert-match --fixed-strings -- "$ignoreLine" out.txt || true; } | sponge out.txt
      fi
    done

    for ignoreLine in "''${ignoreLines[@]}"; do
      scope="''${ignoreLine%%|*}"
      if [ "$scope" != "$ignoreLine" ] && [[ "$scope" =~ ^[A-Za-z0-9_.-]+$ ]]; then
        continue
      fi
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
