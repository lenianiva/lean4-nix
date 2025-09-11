#!/usr/bin/env bash

set -e

VERSION=$1

if [ -z "$VERSION" ]; then
	echo "Must supply a tag"
	VERSION=4.22.0
fi

# Cut the revision by tag
REV=$(git ls-remote -t https://github.com/leanprover/lean4 v$VERSION | cut -f1)

declare -A targets=( [x86_64-linux]=linux [aarch64-darwin]=darwin_aarch64 )

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

printf "rev = \"$REV\";\ntoolchain = {\n"

for target in "${!targets[@]}"; do
	name=${targets[$target]}
	filename=$(construct_filename $name)
	hash=$(nix-prefetch-url --unpack https://github.com/leanprover/lean4/releases/download/v$VERSION/$filename)
	#hash=$(sha256sum /tmp/$filename | cut -d ' ' -f 1)
	printf "  $target = \"$hash\";\n"
done

printf "};"
