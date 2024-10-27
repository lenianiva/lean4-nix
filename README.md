# Lean 4 Nix

Nix flake build for Lean 4.

Features:

- Lean overlay
- Automatically read toolchain version
- Convert `lake-manifest.json` into Lean build

## Example

The default template is a good starting point for projects requiring manual
dependency management:

``` sh
nix flake new --template github:lenianiva/lean4-nix ./minimal
```

The `.#dependency` template shows an example of using `lake-manifest.json` to
fetch dependencies automatically.

``` sh
nix flake new --template github:lenianiva/lean4-nix#dependency ./dependency
```

## Flake outputs

### Overlay

The user must decide on a Lean version to use as overlay. The minimal supported
version is `v4.11.0`, since it is the version when Lean's official Nix flake was
deprecated. There are a couple of ways to get an overlay. Each corresponds to a
flake output:

- `readSrc { src; bootstrap; }`: Builds Lean from a source folder. A
  bootstrapping function must be provided.
- `readFromGit{ args; bootstrap; }`: Given parameters to `builtins.fetchGit`, download a git repository
- `readRev { rev; bootstrap; } `: Reads a revision from the official Lean 4 repository
- `readToolchainFile`: Reads the toolchain from a file. Due to Nix's pure
  evaluation principle, this only supports `leanprover/lean4:{tag}` based
  `lean-toolchain` files. For any other toolchains, use `readRev` or `readFromGit`.
- `tags.{tag}`: Lean4 tags. See the available tags in `manifests/`

Then apply the overlay on `pkgs`:
```nix
pkgs = import nixpkgs {
  inherit system;
  overlays = [ (lean4-nix.readToolchainFile ./lean-toolchain) ];
};
```
and `pkgs.lean` will be replaced by the chosen overlay.

### `pkgs.lean`

This attribute set has properties

- `lean`: The Lean executable
- `lean-all`: `lean`, `lake`, and the Lean library.
- `example`: Use `nix run .#example` to see an example of building a Lean program.
- `Init`, `Std`, `Lean`: Lean built-in libraries provided in the same format as `buildLeanPackage`

and the function `buildLeanPackage`, which accepts a parameter set
`{ name; roots; deps; src; }`. The complete parameter set can be found in Lean
4's `nix/buildLeanPackage.nix` file. In general:
- `src`: The source directory
- `roots`: Lean modules at the root of the import tree.
- `deps`: A list of outputs of other `buildLeanPackage` calls.

This is a form of manual dependency management.

### `lake2nix`

Use `lake2nix = lean4-nix.lake { inherit pkgs; }` to generate the lake utilities.

`lake2nix.mkPackage { src; roots; }` automatically reads the
`lake-manifest.json` file and builds dependencies.

- `src`: The source directory
- `manifestFile`: Path to the manifest file. Defaults to `${src}/lake-manifest.json`
- `roots`: Lean modules at the root of the import tree. Defaults to the project
  name from `manifestFile`
- `deps`: Additional dependencies. Defaults to `[ Init Std Lean ]`.

## Troubleshooting

### attribute '"{Lean,Init}.*"' is missing

If you see this error, add these packages to `deps` in either `buildLeanPackage`
or `mkPackage`.

``` nix
{
  deps = with pkgs.lean; [ Init Std Lean ];
}
```

### Only `leanprover/lean4:{tag}` toolchains are supported

The Lean version is not listed in the `manifests/` directory. Use `readRev` or
`readFromGit` instead.

## Development

Use `nix flake check` to check the template builds.

Update the template `lean-toolchain` files when new Lean versions come out.
