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
  excludeShellChecks = [ "SC2001" ];
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

    unpinned=$(jq -r '
      .nodes | to_entries[]
      | select(.key != "root" and .value.original.type == "github" and (.value.original.ref | not))
      | "\(.key): github:\(.value.original.owner)/\(.value.original.repo) has no branch ref pinned"
    ' plugins/flake.lock)
    if [ -n "$unpinned" ]; then
      status=1
      printf '%s\n' "$unpinned"
    fi

    jq -r '
      .nodes | to_entries[]
      | select(.key != "root" and .value.original.type != "github")
      | "\(.key): not a github input, skipped"
    ' plugins/flake.lock >&2

    sources=$(jq -c . plugins/sources.json)

    moved=$(jq -c '
      [ to_entries[] | select(.value.repo) | { key: .key, value: .value.repo } ] | from_entries
    ' <<<"$sources")

    want=$(jq -c '
      [ to_entries[] | select(.value.ref) | { key: (.value.repo // .key), value: .value.ref } ] | from_entries
    ' <<<"$sources")

    pinned=$(jq -c --argjson want "$want" '
      [ .nodes | to_entries[]
        | select(.key != "root" and .value.original.type == "github" and .value.original.ref != null)
        | { input: .key, owner: .value.original.owner, repo: .value.original.repo, ref: .value.original.ref }
        | . + { want: $want["\(.owner)/\(.repo)"] } ]
    ' plugins/flake.lock)
    if [ "$(jq length <<<"$pinned")" -eq 0 ]; then
      exit "$status"
    fi

    query=$(jq -r '
      to_entries
      | map("q\(.key): repository(owner: \"\(.value.owner)\", name: \"\(.value.repo)\") { nameWithOwner defaultBranchRef { name }"
            + (if .value.want then " wantRef: ref(qualifiedName: \"refs/heads/\(.value.want)\") { name }" else "" end)
            + " }")
      | "{ " + join(" ") + " }"
    ' <<<"$pinned")

    response=$(gh api graphql -f query="$query" 2>/dev/null) || true
    if ! jq -e .data <<<"$response" >/dev/null 2>&1; then
      echo "GitHub GraphQL query failed" >&2
      exit 2
    fi

    findings=$(jq -r --argjson pinned "$pinned" --argjson moved "$moved" '
      . as $resp
      | $pinned | to_entries[]
      | .value as $p
      | $resp.data["q\(.key)"] as $node
      | if $node == null then
          [ "missing", $p.input, $p.owner, $p.repo, $p.ref, "" ]
        elif ($node.defaultBranchRef.name // "") == "" then
          [ "nobranch", $p.input, $p.owner, $p.repo, $p.ref, "" ]
        elif ($node.nameWithOwner | ascii_downcase) != ("\($p.owner)/\($p.repo)" | ascii_downcase) then
          [
            (if $moved["\($p.owner)/\($p.repo)"] == $node.nameWithOwner then "moved-ack" else "moved" end),
            $p.input, $p.owner, $p.repo, $p.ref, $node.nameWithOwner
          ]
        elif $p.want != null and $node.wantRef == null then
          [ "gonebranch", $p.input, $p.owner, $p.repo, $p.ref, $p.want ]
        elif $p.want != null and $p.ref != $p.want then
          [ "wrongbranch", $p.input, $p.owner, $p.repo, $p.ref, $p.want ]
        elif $p.want == null and $p.ref != $node.defaultBranchRef.name then
          [ "outdated", $p.input, $p.owner, $p.repo, $p.ref, $node.defaultBranchRef.name ]
        else
          empty
        end
      | @tsv
    ' <<<"$response")
    if [ -z "$findings" ]; then
      exit "$status"
    fi

    while IFS=$'\t' read -r kind input owner repo ref extra; do
      case "$kind" in
        missing)
          status=1
          echo "$input: github:$owner/$repo not found on GitHub"
          ;;
        nobranch)
          status=1
          echo "$input: github:$owner/$repo has no default branch (empty repository?)"
          ;;
        moved)
          status=1
          echo "$input: github:$owner/$repo has moved to $extra"
          ;;
        moved-ack)
          echo "$input: github:$owner/$repo move to $extra stated in plugins/sources.json" >&2
          ;;
        gonebranch)
          status=1
          echo "$input: plugins/sources.json requires branch $extra but github:$owner/$repo no longer has it"
          ;;
        outdated | wrongbranch)
          status=1
          if [ "$kind" = wrongbranch ]; then
            echo "$input: pinned to $owner/$repo/$ref but LazyVim requires $extra"
          else
            echo "$input: pinned to $owner/$repo/$ref but default branch is $extra"
          fi
          if [ "$fix" = 1 ]; then
            old="github:$owner/$repo/$ref\""
            new="github:$owner/$repo/$extra\""
            sed -i "s|$(sed 's/[][\.*^$|]/\\&/g' <<<"$old")|$(sed 's/[&\|]/\\&/g' <<<"$new")|" plugins/flake.nix
            if ! grep -qF "$new" plugins/flake.nix; then
              echo "$input: failed to rewrite plugins/flake.nix" >&2
              exit 2
            fi
            nix flake update "$input" --flake ./plugins
          fi
          ;;
      esac
    done <<<"$findings"

    exit "$status"
  '';
}
