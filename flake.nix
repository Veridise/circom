{
  inputs = {
    naersk.url = "github:nix-community/naersk/master";
    utils.url = "github:numtide/flake-utils/v1.0.0";
  };

  outputs = { self, nixpkgs, utils, naersk }:

    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        naersk-lib = pkgs.callPackage naersk { };
      in rec {
        defaultPackage = with pkgs; naersk-lib.buildPackage {
           name = "circom";
           pname = "circom";
           src = ./.;

           buildInputs = [ llvmPackages_13.libllvm libffi libiconv libxml2 zlib  ];
           installCheckInputs = [ lit ];

           installCheckPhase = ''
               runHook preCheck
               export PATH="$out"/bin:"$PATH"
               lit -v --no-progress tests
               runHook postCheck
             '';

           doCheck = true;

           LLVM_SYS_130_PREFIX = "${llvmPackages_13.libllvm.dev}";
         };

        devShell = with pkgs; mkShell {
          buildInputs = [ cargo rustc rustfmt pre-commit rustPackages.clippy lit ];
          RUST_SRC_PATH = rustPlatform.rustLibSrc;
        };
      });
}
