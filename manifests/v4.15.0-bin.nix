rec {
  tag = "v4.15.0";
  rev = "11651562caae0a0b3973811508db2ab8903d3854";
  bootstrap = {
    lib,
    stdenv,
    cadical,
    cmake,
    git,
    gmp,
    libuv,
    perl,
    symlinkJoin,
    writeShellScriptBin,
  }: let
    lean4 = stdenv.mkDerivation {
      pname = "lean4";
      version = lib.substring 1 (-1) tag;
      src = builtins.fetchGit {
        url = "https://github.com/leanprover/lean4";
        inherit rev;
        ref = "refs/tags/${tag}";
        shallow = true;
      };

      postPatch = ''
        substituteInPlace src/CMakeLists.txt \
          --replace-fail 'set(GIT_SHA1 "")' 'set(GIT_SHA1 "${rev}")'

        # Remove tests that fails in sandbox.
        # It expects `sourceRoot` to be a git repository.
        rm -rf src/lake/examples/git/
      '';

      preConfigure = ''
        patchShebangs stage0/src/bin/ src/bin/
      '';

      nativeBuildInputs = [
        cmake
      ];

      buildInputs = [
        gmp
        libuv
        cadical
      ];

      nativeCheckInputs = [
        git
        perl
      ];

      cmakeFlags = [
        "-DUSE_GITHASH=OFF"
        "-DINSTALL_LICENSE=OFF"
      ];

      meta.mainProgram = "lean";
    };

    lean = writeShellScriptBin "lean" ''
      exec ${lib.getExe lean4} "$@"
    '';

    leanc = writeShellScriptBin "leanc" ''
      exec ${lib.getExe' lean4 "leanc"} "$@"
    '';

    lake = writeShellScriptBin "lake" ''
      exec ${lib.getExe' lean4 "lake"} "$@"
    '';

    # TODO: export standalone Init Std Lean Lake

    buildLeanPackage = {
      name,
      src ? null,
      deps ? [],
      roots ? [],
      ...
    }: let
      drv = stdenv.mkDerivation {
        inherit name src;

        nativeBuildInputs = [lean4];

        # FIXME: not working
        # error: [root]: no configuration file with a supported extension:
        # ././lakefile.lean
        # ././lakefile.toml
        buildPhase = ''
          runHook preBuild
          lake build
          runHook postBuild
        '';

        # #FIXME: placeholder
        # might not export bin
        installPhase = ''
          runHook preInstall
          mkdir -p $out/bin
          cp build/bin/* $out/bin/ 2>/dev/null || true
          runHook postInstall
        '';
      };
    in
      drv
      // {
        executable = drv;
        inherit deps roots;
      };

    lean-all = symlinkJoin {
      name = "lean-all";
      # FIXME: prob dont need both lean4 and lean
      # also lean4 seem to include Init Std Lean Lake
      paths = [lean4 lean leanc lake];
    };
  in {
    inherit stdenv; # TODO: prob not needed
    inherit lean leanc lake lean-all;
    inherit buildLeanPackage;
  };
}
