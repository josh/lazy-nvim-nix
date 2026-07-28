{
  writeShellApplication,
  gh,
  git,
  gnused,
  jq,
}:
writeShellApplication {
  name = "check-plugin-sources";
  runtimeInputs = [
    gh
    git
    gnused
    jq
  ];
  text = ''
    fix=0
    if [ "''${1:-}" = "--fix" ]; then
      fix=1
    elif [ "$#" -gt 0 ]; then
      echo "usage: check-plugin-sources [--fix]" >&2
      exit 2
    fi

    cd "$(git rev-parse --show-toplevel)"

    status=0

    while IFS=$'\t' read -r input owner repo; do
      status=1
      echo "$input: github:$owner/$repo has no branch ref pinned"
    done < <(jq -r '
      .nodes | to_entries[]
      | select(.key != "root" and .value.original.type == "github" and (.value.original.ref | not))
      | [.key, .value.original.owner, .value.original.repo] | @tsv
    ' plugins/flake.lock)

    inputs=$(jq -r '
      .nodes | to_entries[]
      | select(.key != "root" and .value.original.type == "github" and .value.original.ref != null)
      | [.key, .value.original.owner, .value.original.repo, .value.original.ref] | @tsv
    ' plugins/flake.lock)

    query="{"
    i=0
    while IFS=$'\t' read -r input owner repo ref; do
      query+=" q$i: repository(owner: \"$owner\", name: \"$repo\") { nameWithOwner defaultBranchRef { name } }"
      i=$((i + 1))
    done <<<"$inputs"
    query+=" }"

    if ! response=$(gh api graphql -f query="$query"); then
      echo "GitHub GraphQL query failed" >&2
      exit 2
    fi

    i=0
    while IFS=$'\t' read -r input owner repo ref; do
      node=$(jq -r ".data.q$i // empty" <<<"$response")
      i=$((i + 1))
      if [ -z "$node" ]; then
        status=1
        echo "$input: github:$owner/$repo not found on GitHub"
        continue
      fi
      slug=$(jq -r .nameWithOwner <<<"$node")
      default=$(jq -r .defaultBranchRef.name <<<"$node")
      if [ "$slug" != "$owner/$repo" ]; then
        status=1
        echo "$input: github:$owner/$repo has moved to $slug"
        continue
      fi
      if [ "$ref" != "$default" ]; then
        status=1
        echo "$input: pinned to $owner/$repo/$ref but default branch is $default"
        if [ "$fix" = 1 ]; then
          pattern="github:$owner/$repo/$ref\""
          replacement="github:$owner/$repo/$default\""
          sed -i "s|''${pattern//./\\.}|$replacement|" plugins/flake.nix
          nix flake update "$input" --flake ./plugins
        fi
      fi
    done <<<"$inputs"

    exit "$status"
  '';
}
