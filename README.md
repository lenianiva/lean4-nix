# Lean 4 Nix

[![built with garnix](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Fgarnix.io%2Fapi%2Fbadges%2Flenianiva%2Flean4-nix)](https://garnix.io/repo/lenianiva/lean4-nix)

Nix flake build for Lean 4.

Features:

- Build Lean with Nix
- Build Lean Projects (with executables and libraries) with Nix
- Lean overlay
- Automatically read toolchain version
- Convert `lake-manifest.json` into Lean build

## Example

The default minimal template is for projects requiring manual dependency
management:

``` sh
nix flake new --template github:lenianiva/lean4-nix ./minimal
```

The `.#dependency` template shows an example of using `lake-manifest.json` to
fetch dependencies automatically.

``` sh
nix flake new --template github:lenianiva/lean4-nix#dependency ./dependency
```

## Caching

This project has CI by Garnix and uses
[`cache.garnix.io`](https://garnix.io/docs/caching) for binary caching. To use
the cache, there must be a match between the nixpkgs version listed in
`flake.lock` and the downstream project. Only the newest version will be cached.

## Flake outputs

### Packages

The flake's `packages.${system}.lean` output contains the Lean and lake
executables. The version corresponds to the latest version in the `manifests/`
directory.

- `lean-all`: `lean` and `lake`
- `lean`/`leanc`/`lake`: Executables
- `leanshared`: Shared library of Lean
- `cacheRoots`: Cached derivations to enable binary caching.
- `buildLeanPackage`: See below

### Overlay

The user must decide on a Lean version to use as overlay. The Lean version from
`nixpkgs` will likely not work of the box. The minimal supported version is
`v4.11.0`, since it is the version when Lean's official Nix flake was
deprecated. From version `v4.22.0` onwards, the each Lean build must have both
`bootstrap` and `buildLeanPackage` functions. There are a couple of ways to get
an overlay.  Each corresponds to a flake output. Below is a list ranked from the
easiest to the hardest to use:

- `readToolchainFile { toolchain; binary ? true; }`: Reads the toolchain from a
  file. Due to Nix's pure evaluation principle, this only supports
  `leanprover/lean4:{tag}` based `lean-toolchain` files. For any other
  toolchains, use `readRev` or `readFromGit`.
- `readToolchain { toolchain; binary ? true };`: `readToolchainFile` but with
  its contents provided directly.
- `readBinaryToolchain manifest`: Reads the binary toolchain from a manifest
  given in the same format as `manifests/*.nix`.
- `tags.{tag}`: Lean4 tags. See the available tags in `manifests/`
- `readRev { rev; bootstrap; buildLeanPackage; } `: Reads a revision from the
  official Lean 4 repository
- `readFromGit{ args; bootstrap; buildLeanPackage; }`: Given parameters to
  `builtins.fetchGit`, download a git repository
- `readSrc { src; bootstrap; buildLeanPackage; }`: Builds Lean from a source folder. A
  bootstrapping function must be provided.

Then apply the overlay on `pkgs`:
```nix
pkgs = import nixpkgs {
  inherit system;
  overlays = [ (lean4-nix.readToolchainFile ./lean-toolchain) ];
};
```

and `pkgs.lean` will be replaced by the chosen overlay.

Some users may wish to build nightly or release candidate versions without a
corresponding manifest in `manifests/`. In this case, a common solution is to
import the `bootstrap` and `buildLeanPackage` functions from the nearest major
version and feed it to `readRev`. In cases where there is a major change to the
`bootstrap`/`buildLeanPackage` function, the user may need to create the
function on their own.

### `pkgs.lean`

This attribute set has properties

- `lean`: The Lean executable
- `lean-all`: `lean`, `lake`, and the Lean library.
- `example`: Use `nix run .#example` to see an example of building a Lean program.
- `Init`, `Std`, `Lean`: Lean built-in libraries provided in the same format as
  `buildLeanPackage`

and the function `buildLeanPackage`, which accepts a parameter set
`{ name; roots; deps; src; }`. The complete parameter set can be found in [the
v4.22.0 manifest](manifests/v4.22.0.nix). In general:
- `src`: The source directory
- `roots`: Lean modules at the root of the import tree.
- `deps`: A list of outputs of other `buildLeanPackage` calls.

This is a form of manual dependency management.

### `lake2nix`

Use `lake2nix = pkgs.callPackage lean4-nix.lake {}` to generate the lake utilities.

`lake2nix.mkPackage { ... }` automatically reads the `lake-manifest.json` file
and builds dependencies. It takes the following arguments:

- `src`: The source directory
- `manifestFile ? ${src}/lake-manifest.json`: Path to the manifest file.
- `roots`: Lean modules at the root of the import tree. Defaults to the project
  name from `manifestFile`
- `deps ? [ Init Std Lean ]`: Additional Lean package dependencies.
- `staticLibDeps ? []`: List of static libraries to link with.

### `buildLeanPackage`

The `buildLeanPackage` and `mkPackage` functions output the built Lean package
in a non-derivation format. Generally, the attributes available are:
- `executable`: Executable
- `sharedLib`: Shared library
- `modRoot`: Module root. Set `LEAN_PATH` to this to provide context for LSP.
- `cTree`, `oTree`, `iTree`: Trees of C files/`.o` files/`.ilean` files

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

Update the template `lean-toolchain` files when new Lean versions come out. When
a new version is released, execute

``` sh
toolchain fetch $VERSION
```
to generate new toolchain hashes.

All code must be formatted with `alejandra` before merging into `main`. To use
it, execute

```sh
nix fmt .
```
