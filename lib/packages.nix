args @ {
  bootstrap,
  callPackage,
  lib,
  llvmPackages,
  buildLeanPackage ? null,
  src,
}: let
  lean = callPackage bootstrap (args
    // {
      inherit (llvmPackages) stdenv;
      inherit src llvmPackages;
      buildLeanPackage = buildLeanPackageOverride;
    });

  makeOverridableLeanPackage = f: let
    newF = origArgs:
      f origArgs
      // {
        overrideArgs = newArgs: makeOverridableLeanPackage f (origArgs // newArgs);
      };
  in
    lib.setFunctionArgs newF (lib.functionArgs f)
    // {
      override = args: makeOverridableLeanPackage (f.override args);
    };

  buildLeanPackageOverride = makeOverridableLeanPackage (
    callPackage (
      if builtins.isNull buildLeanPackage
      # Only exists for versions 4.21 and below.
      then import "${src}/nix/buildLeanPackage.nix"
      else buildLeanPackage
    )
      (args
    // {
      inherit (lean) stdenv;
      lean = lean.stage1;
      inherit (lean.stage1) leanc;
    }
      ));
in
  {buildLeanPackage = buildLeanPackageOverride;} // lean.stage1
