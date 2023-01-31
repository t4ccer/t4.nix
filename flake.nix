{
  description = "t4.nix";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    pre-commit-hooks-nix = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs";
    };
    hello = {
      url = "https://ftp.gnu.org/gnu/hello/hello-2.12.1.tar.gz";
      flake = false;
    };
  };
  outputs = inputs @ {
    self,
    nixpkgs,
    ...
  }:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.pre-commit-hooks-nix.flakeModule

        # If you're using this repo as a flake input,
        # instead use: inputs.t4-nix.formatCheck
        # ./format-check.nix # FIXME
        ./stdenv-matrix.nix
        ./build-all.nix
      ];
      systems =
        if builtins.hasAttr "currentSystem" builtins
        then [builtins.currentSystem]
        else inputs.nixpkgs.lib.systems.flakeExposed;
      flake = {
        # formatCheck = ./format-check.nix;
        stdenvMatrix = ./stdenv-matrix.nix;
        buildAll = ./build-all.nix;
      };
      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: {
        pre-commit.settings = {
          src = ./.;
          hooks = {
            alejandra.enable = true;
            statix.enable = true;
          };
        };

        devShells.default = pkgs.mkShell {
          shellHook = config.pre-commit.installationScript;
          nativeBuildInputs = [
            pkgs.alejandra
            pkgs.fd
          ];
        };

        stdenvMatrix = {
          hello = {
            # List of stdenvs to use
            stdenvs = ["stdenv" "clangStdenv"];
            # Attrs that will be passed to `pkgs.<stenvd>.mkDerivaton`
            mkDerivationAttrs = {
              pname = "hello";
              version = "2.12.1";
              src = inputs.hello.outPath;
              doCheck = true;
            };
          };
        };

        buildAll.enable = true;

        formatter = pkgs.alejandra;
      };
    };
}
