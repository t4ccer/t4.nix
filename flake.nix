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
        ./format-check.nix
      ];
      systems =
        if builtins.hasAttr "currentSystem" builtins
        then [builtins.currentSystem]
        else inputs.nixpkgs.lib.systems.flakeExposed;
      flake = {
        formatCheck = ./format-check.nix;
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
        formatCheck.enable = true;
        formatter = pkgs.alejandra;
      };
    };
}
