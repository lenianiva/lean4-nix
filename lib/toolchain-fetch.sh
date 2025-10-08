#!/usr/bin/env bash

set -euo pipefail

VERSION=$1

if [ -z "$VERSION" ]; then
	echo "Must supply a tag"
	exit 1
fi

# Cut the revision by tag
REV=$(git ls-remote -t https://github.com/leanprover/lean4 v$VERSION | cut -f1)

declare -A targets=(
	[x86_64-linux]=linux
	[aarch64-linux]=linux_aarch64
	[x86_64-darwin]=darwin
	[aarch64-darwin]=darwin_aarch64
)

construct_filename() {
	printf "lean-$VERSION-$1.tar.zst"
}

# Download the targets

#for target in "${!targets[@]}"; do
#	name=${targets[$target]}
#	filename=$(construct_filename $name)
#	if [ ! -f "/tmp/$filename" ]; then
#		wget -nv https://github.com/leanprover/lean4/releases/download/v$VERSION/$filename \
#			-O /tmp/$filename
#	fi
#	echo "Fetching $target -> $filename"
#done

# Print Nix code

printf "tag = \"v$VERSION\";\n"
printf "rev = \"$REV\";\ntoolchain = {\n"

for target in "${!targets[@]}"; do
	name=${targets[$target]}
	filename=$(construct_filename $name)
	prefetch=$(nix --extra-experimental-features nix-command store prefetch-file --json --hash-type sha256 https://github.com/leanprover/lean4/releases/download/v$VERSION/$filename)
	hash=$(jq -r '.hash' <<< "$prefetch")
	printf "  $target.hash = \"$hash\";\n"
done

printf "};"
