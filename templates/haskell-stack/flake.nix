{
  description = "haskell-stack-template";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    pre-commit-hooks-nix = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {flake-parts, ...}: let
    ghcVer = "ghc944";
    fourmoluVer = "fourmolu";
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.pre-commit-hooks-nix.flakeModule
      ];

      # Hack to make following work with IFD:
      # nix flake show --impure --allow-import-from-derivation
      systems =
        if builtins.hasAttr "currentSystem" builtins
        then [builtins.currentSystem]
        else inputs.nixpkgs.lib.systems.flakeExposed;

      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: {
        pre-commit.settings = {
          hooks = {
            alejandra.enable = true;
            statix.enable = true;
            fourmolu.enable = true;
          };
          tools.fourmolu = pkgs.lib.mkForce pkgs.haskell.packages.${ghcVer}.${fourmoluVer};
          settings.ormolu.defaultExtensions = [
            "QuasiQuotes"
            "TemplateHaskell"
            "TypeApplications"
            "ImportQualifiedPost"
            "PatternSynonyms"
            "OverloadedRecordDot"
          ];
        };

        devShells.default = let
          stackWithSystemGHC = pkgs.writeShellScriptBin "stack" ''
            ${pkgs.stack}/bin/stack --system-ghc --no-nix "$@"
          '';
        in
          pkgs.mkShell {
            shellHook = config.pre-commit.installationScript;
            nativeBuildInputs = [
              # MUST match stack snapshot
              pkgs.haskell.compiler.${ghcVer}
              pkgs.cabal-install
              stackWithSystemGHC
              pkgs.haskell.packages.${ghcVer}.${fourmoluVer}
              # pkgs.haskell.packages.${ghcVer}.haskell-language-server
              pkgs.zlib
            ];
          };
      };
    };
}
