{
  lib,
  stdenv,
  writeText,
  runCommand,
  glibcLocales,
  lazy-nvim-nix,
}:
let
  neovim = lazy-nvim-nix.LazyVim;
  vim-script-runner = writeText "lazyvim-config-json.vim" ''
    doautocmd UIEnter
    lua vim.wait(3000, function() return vim.g.did_very_lazy == true end, 50)
    lua for _, p in pairs(require("lazy.core.config").plugins) do if not (p.dir or ""):find("^/nix/store/") then io.stderr:write(p.name .. " is not store-wired, dir=" .. tostring(p.dir) .. "\n") vim.cmd("cquit!") end end
    lua for _, name in ipairs({ "fzf-lua", "neo-tree.nvim", "telescope.nvim" }) do if require("lazy.core.config").plugins[name] ~= nil then io.stderr:write(name .. " was imported from the user lazyvim.json\n") vim.cmd("cquit!") end end
    lua if not tostring(require("lazyvim.config").json.path):find("^/nix/store/") then io.stderr:write("lazyvim.json path not in the store: " .. tostring(require("lazyvim.config").json.path) .. "\n") vim.cmd("cquit!") end
    lua local j = require("lazyvim.config").json if j.data.version ~= j.version then io.stderr:write("generated lazyvim.json version drifted; migration would run every startup\n") vim.cmd("cquit!") end
    qall!
  '';
  hostile-old-install = writeText "lazyvim-old.json" ''
    {"version":8,"install_version":7,"extras":[],"news":{}}
  '';
  hostile-extras = writeText "lazyvim-extras.json" ''
    {"version":8,"install_version":8,"extras":["lazyvim.plugins.extras.editor.telescope"],"news":{}}
  '';
in
runCommand "lazyvim-config-json"
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
    hostileFiles = [
      "${hostile-old-install}"
      "${hostile-extras}"
    ];

    env = {
      DISPLAY = lib.optionalString stdenv.hostPlatform.isLinux ":0";
      LOCALE_ARCHIVE = lib.optionalString stdenv.hostPlatform.isLinux "${glibcLocales}/lib/locale/locale-archive";
      LANG = "en_US.UTF-8";
    };
  }
  ''
    i=0
    for hostile in "''${hostileFiles[@]}"; do
      home="$PWD/home$i"
      mkdir -p "$home/.config/nvim"
      install -m 644 "$hostile" "$home/.config/nvim/lazyvim.json"
      touch "$home/.config/nvim/init.lua"

      exit_code=0
      HOME="$home" timeout --kill-after=10s 120s "$neovimBin" "''${nvimArgs[@]}" 1>out.txt 2>err.txt || exit_code=$?

      echo "== variant $i stdout =="
      cat out.txt
      echo "== variant $i stderr =="
      cat err.txt
      echo "=="

      if [ "$exit_code" -eq 124 ] || [ "$exit_code" -eq 137 ]; then
        echo "Test timed out (exit $exit_code)"
        exit 1
      elif [ "$exit_code" -ne 0 ]; then
        echo "Neovim exited with code $exit_code"
        exit 1
      elif grep "^E[0-9]\+: " err.txt; then
        exit 1
      fi

      cmp "$hostile" "$home/.config/nvim/lazyvim.json"
      i=$((i + 1))
    done

    touch $out
  ''
