{
  writeShellApplication,
  gh,
  git,
  jq,
}:
writeShellApplication {
  name = "check-plugin-sources";
  runtimeInputs = [
    gh
    git
    jq
  ];
  text = ''
    fix=0
    if [ "''${1:-}" = "--fix" ]; then
      fix=1
    fi

    cd "$(git rev-parse --show-toplevel)"

    status=0
    while IFS=$'\t' read -r input owner repo ref; do
      default=$(gh api "repos/$owner/$repo" --jq .default_branch)
      if [ "$ref" != "$default" ]; then
        status=1
        echo "$input: pinned to $owner/$repo/$ref but default branch is $default"
        if [ "$fix" = 1 ]; then
          sed -i.bak "s|github:$owner/$repo/$ref|github:$owner/$repo/$default|" plugins/flake.nix
          rm -f plugins/flake.nix.bak
          nix flake update "$input" --flake ./plugins
        fi
      fi
    done < <(jq -r '
      .nodes | to_entries[]
      | select(.key != "root" and .value.original.type == "github" and .value.original.ref != null)
      | [.key, .value.original.owner, .value.original.repo, .value.original.ref] | @tsv
    ' plugins/flake.lock)

    exit "$status"
  '';
}
