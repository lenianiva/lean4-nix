#!/usr/bin/env bash

set -eo pipefail

VERSION=$1
LABEL_VERSION=$2

if [ -z "$VERSION" ]; then
	echo "Must supply a tag"
	exit 1
fi

REPO=https://github.com/leanprover/lean4

printf "tag = \"v$VERSION\";\n"

# Cut the revision by tag
rev=$(git ls-remote -t $REPO v$VERSION | cut -f1)

printf "rev = \"$rev\";\n"
repo_info=$(nix flake prefetch --extra-experimental-features 'nix-command flakes' --json git+$REPO?allRefs=1&ref=$rev)

hash=$(jq -r '.hash' <<< "$repo_info")
printf "hash = \"$hash\";\ntoolchain = {\n"

declare -A targets=(
	[x86_64-linux]=linux
	[aarch64-linux]=linux_aarch64
	[x86_64-darwin]=darwin
	[aarch64-darwin]=darwin_aarch64
)

# Print Nix code


for target in "${!targets[@]}"; do
	target_name=${targets[$target]}
	url=https://github.com/leanprover/lean4/releases/download/v$VERSION/lean-${LABEL_VERSION:-$VERSION}-$target_name.tar.zst
	prefetch=$(nix --extra-experimental-features nix-command store prefetch-file --json --hash-type sha256 $url)
	hash=$(jq -r '.hash' <<< "$prefetch")
	printf "  $target = {\n"
	printf "    url = \"$url\";\n"
	printf "    hash = \"$hash\";\n"
	printf "  };\n"
done

printf "};"
