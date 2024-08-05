#!/bin/sh

set -e
set -x

nix flake update \
  --reference-lock-file flake.lock \
  --output-lock-file flake.lock

nix flake update \
  --reference-lock-file flake-dev.lock \
  --override-input treefmt-nix 'github:numtide/treefmt-nix' \
  --output-lock-file flake-dev.lock
