{
  inputs = {
    llzk-pkgs.url = "github:Veridise/llzk-nix-pkgs";

    nixpkgs = {
      url = "github:NixOS/nixpkgs";
      follows = "llzk-pkgs/nixpkgs";
    };

    flake-utils = {
      url = "github:numtide/flake-utils/v1.0.0";
      follows = "llzk-pkgs/flake-utils";
    };

    llzk = {
      url = "github:Veridise/llzk-lib/main";
      inputs = {
        nixpkgs.follows = "llzk-pkgs/nixpkgs";
        flake-utils.follows = "llzk-pkgs/flake-utils";
        llzk-pkgs.follows = "llzk-pkgs";
      };
    };

    release-helpers.follows = "llzk/release-helpers";
  };

  # Custom colored bash prompt
  nixConfig.bash-prompt = "\\[\\e[0;32m\\][circom]\\[\\e[m\\] \\[\\e[38;5;244m\\]\\w\\[\\e[m\\] % ";

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      release-helpers,
      llzk-pkgs,
      llzk,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            release-helpers.overlays.default
            llzk-pkgs.overlays.default
            llzk.overlays.default
          ];
        };
        # Create a merged LLVM + MLIR derivation because mlir-sys uses llvm-config to
        # discover information about both (mainly the MLIR includes are missing).
        llvmWithMlir = pkgs.symlinkJoin {
          name = "llvm-with-mlir";
          paths = [
            pkgs.llzk_llvmPackages.libllvm.dev
            pkgs.llzk_llvmPackages.mlir.dev
          ];
        };
        circomNativeBuildInputs = [
          pkgs.cmake
          pkgs.llzk_llvmPackages.clang
          pkgs.llzk_llvmPackages.clang-tools
        ];
        circomBuildInputs = [
          llvmWithMlir
          pkgs.llzk
          pkgs.libffi
          pkgs.libiconv
          pkgs.libxml2
          pkgs.zlib
        ];
      in
      {
        packages = flake-utils.lib.flattenTree {
          inherit (pkgs) llzk llzk_debug changelogCreator;
          # For debug purposes, expose the MLIR/LLVM packages.
          inherit (pkgs) mlir mlir_debug;
          # Prevent use of libllvm and llvm from nixpkgs, which will have
          # different versions than the mlir from llzk-pkgs.
          inherit (pkgs.llzk_llvmPackages) libllvm llvm;

          default = pkgs.rustPlatform.buildRustPackage rec {
            pname = "circom-to-llzk";
            version = "0.1.0";
            src = ./.;

            nativeBuildInputs = circomNativeBuildInputs;
            buildInputs = circomBuildInputs;
            cargoLock = {
              lockFile = ./Cargo.lock;
              outputHashes = {
                "llzk-0.1.0" = "sha256-V0jsnzw9QwjJB0De7zrX+U+s/fYn4k9nWfHCSQn2O9Q=";
              };
            };

            MLIR_SYS_200_PREFIX = "${llvmWithMlir}";
            TABLEGEN_200_PREFIX = "${llvmWithMlir}";
          };
        };

        devShells = flake-utils.lib.flattenTree {
          default = pkgs.mkShell {
            nativeBuildInputs = circomNativeBuildInputs ++ [
              pkgs.git
            ];
            buildInputs = circomBuildInputs ++ [
              pkgs.cargo
              pkgs.rustc
              pkgs.rustfmt
              pkgs.rustPackages.clippy
            ];

            RUST_SRC_PATH = pkgs.rustPlatform.rustLibSrc;
            MLIR_SYS_200_PREFIX = "${llvmWithMlir}";
            TABLEGEN_200_PREFIX = "${llvmWithMlir}";
            CARGO_INCREMENTAL = 1; # speed up rebuilds
            RUST_BACKTRACE = 1; # enable backtraces

            shellHook = ''
              ## Bail out of pipes where any command fails
              set -uo pipefail
              echo "Welcome to the circom-to-llzk devshell!"
            '';
          };
        };
      }
    );
}
